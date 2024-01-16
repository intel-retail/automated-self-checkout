//*****************************************************************************
// Copyright 2023 Intel Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//*****************************************************************************
#include <algorithm>
#include <array>
#include <chrono>
#include <cstring>
#include <iostream>
#include <numeric>
#include <sstream>
#include <thread>
#include <vector>
#include <iomanip>
#include <regex>
#include <atomic>
#include <mutex>
#include <condition_variable>

#include <signal.h>
#include <stdio.h>

// Utilized for GStramer hardware accelerated decode and pre-preprocessing
#include <gst/gst.h>
#include <gst/app/gstappsrc.h>
#include <gst/app/gstappsink.h>

// Utilized for OpenCV based Rendering only
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>

// Utilized for infernece output layer post-processing
#include <cmath>

#include "ovms.h"  // NOLINT

#include "barcode.cpp"

using namespace std;
using namespace cv;

std::mutex _mtx;
std::mutex _infMtx;
std::mutex _drawingMtx;
std::condition_variable _cvAllDecodersInitd;
bool _allDecodersInitd = false;

typedef struct DetectedResult {
	int frameId;
	int x;
	int y;
	int width;
	int height;
	float confidence;
	int classId;
	char classText[1024];
} DetectedResult;

class MediaPipelineServiceInterface {
public:
    enum VIDEO_TYPE {
        H265,
        H264
    };

    virtual ~MediaPipelineServiceInterface() {}
    virtual const std::string getVideoDecodedPreProcessedPipeline(std::string mediaLocation, VIDEO_TYPE videoType, int video_width, int video_height, bool use_onevpl) = 0;
    virtual const std::string getBroadcastPipeline() = 0;
    virtual const std::string getRecordingPipeline() = 0;

    const std::string updateVideoDecodedPreProcessedPipeline(int video_width, int video_height, bool use_onevpl)
    {
        return getVideoDecodedPreProcessedPipeline(m_mediaLocation, m_videoType, video_width, video_height, use_onevpl);
    }

protected:
    std::string m_mediaLocation;
    VIDEO_TYPE m_videoType;
    int m_videoWidth;
    int m_videoHeight;
};

OVMS_Server* _srv;
OVMS_ServerSettings* _serverSettings = 0;
OVMS_ModelsSettings* _modelsSettings = 0;
int _server_grpc_port;
int _server_http_port;

std::string _videoStreamPipeline;
MediaPipelineServiceInterface::VIDEO_TYPE _videoType = MediaPipelineServiceInterface::VIDEO_TYPE::H264;
int _detectorModel = 0;
bool _render = 0;
bool _use_onevpl = 0;
bool _renderPortrait = 0;
cv::Mat _presentationImg;
int _video_input_width = 0;  // Get from media _img
int _video_input_height = 0; // Get from media _img
std::vector<cv::VideoCapture> _vidcaps;
int _window_width = 1280;
int _window_height = 720;
float _detection_threshold = 0.5;
bool _barcode = 1;

class GStreamerMediaPipelineService : public MediaPipelineServiceInterface {
public:
    const std::string getVideoDecodedPreProcessedPipeline(std::string mediaLocation, VIDEO_TYPE videoType, int video_width, int video_height, bool use_onevpl) {
        m_mediaLocation = mediaLocation;
        m_videoType = videoType;
        m_videoWidth = video_width;
        m_videoHeight = video_height;

        if (mediaLocation.find("rtsp") != std::string::npos ) {
        // video/x-raw(memory:VASurface),format=NV12
            switch (videoType)
            {
                case H264:
                if (use_onevpl)
                    return "rtspsrc location=" + mediaLocation + " ! rtph264depay ! h264parse ! " +
                    "msdkh264dec ! msdkvpp scaling-mode=lowpower ! " +
                    "video/x-raw, width=" + std::to_string(video_width) +
                    ", height=" + std::to_string(video_height) + " ! videoconvert ! video/x-raw,format=BGR ! queue ! appsink drop=1 sync=0";
                else
                    return "rtspsrc location=" + mediaLocation + " ! rtph264depay ! vaapidecodebin ! video/x-raw(memory:VASurface),format=NV12 ! vaapipostproc" +
                    " width=" + std::to_string(video_width) +
                    " height=" + std::to_string(video_height) +
                    " scale-method=fast ! videoconvert ! video/x-raw,format=BGR ! queue ! appsink drop=1 sync=0";
                case H265:
                if (use_onevpl)
                    return "rtspsrc location=" + mediaLocation + " ! rtph265depay ! h265parse ! " +
                    "msdkh265dec ! " +
                    "msdkvpp scaling-mode=lowpower ! " +
                    "video/x-raw, width=" + std::to_string(video_width) +
                    ", height=" + std::to_string(video_height) + " ! videoconvert ! video/x-raw,format=BGR ! queue ! appsink drop=1 sync=0";
                else
                    return "rtspsrc location=" + mediaLocation + " ! rtph265depay ! vaapidecodebin ! vaapipostproc" +
                    " width=" + std::to_string(video_width) +
                    " height=" + std::to_string(video_height) +
                    " scale-method=fast ! videoconvert ! video/x-raw,format=BGR ! appsink sync=0 drop=1";
                default:
                    std::cout << "Video type not supported!" << std::endl;
                    return "";
            }
        }
        else if (mediaLocation.find(".mp4") != std::string::npos ) {
            switch (videoType)
            {
                case H264:
                if (use_onevpl)
                    return "filesrc location=" + mediaLocation + " ! qtdemux ! h264parse ! " +
                    "msdkh264dec ! msdkvpp scaling-mode=lowpower ! " +
                    "video/x-raw, width=" + std::to_string(video_width) + ", height=" + std::to_string(video_height) + 
                    " ! videoconvert ! video/x-raw,format=BGR ! queue ! appsink drop=1 sync=0";
                else
                    return "filesrc location=" + mediaLocation + " ! qtdemux ! h264parse ! vaapidecodebin ! vaapipostproc" +
                    " width=" + std::to_string(video_width) +
                    " height=" + std::to_string(video_height) +
                    " scale-method=fast ! videoconvert ! video/x-raw,format=BGR ! appsink drop=1 sync=0";
                case H265:
                if (use_onevpl)
                    return "filesrc location=" + mediaLocation + " ! qtdemux ! h265parse ! " +
                    "msdkh265dec ! msdkvpp scaling-mode=lowpower ! " +
                    " video/x-raw, width=" + std::to_string(video_width) + ", height=" + std::to_string(video_height) +
                    " ! videoconvert ! video/x-raw,format=BGR ! queue ! appsink drop=1 sync=0";
                else
                    return "filesrc location=" + mediaLocation + " ! qtdemux ! h265parse ! vaapidecodebin ! vaapipostproc" +
                    " width=" + std::to_string(video_width) +
                    " height=" + std::to_string(video_height) +
                    " scale-method=fast ! videoconvert ! video/x-raw,format=BGR ! appsink drop=1 sync=0";
                default:
                    std::cout << "Video type not supported!" << std::endl;
                    return "";
            }
        }
        else {
            std::cout << "Unknown media source specified " << mediaLocation << " !!" << std::endl;
            return "";
        }
    }

    const std::string getBroadcastPipeline() {
        return "videotestsrc ! videoconvert,format=BGR ! video/x-raw ! appsink drop=1";
    }

    const std::string getRecordingPipeline() {
        return "videotestsrc ! videoconvert,format=BGR ! video/x-raw ! appsink drop=1";
    }
protected:

};

class ObjectDetectionInterface {
public:
    const static size_t MODEL_DIM_COUNT = 4;
    int64_t model_input_shape[MODEL_DIM_COUNT] = { 0 };

    virtual ~ObjectDetectionInterface() {}
    virtual const char* getModelName() = 0;
    virtual const uint64_t getModelVersion() = 0;
    virtual const char* getModelInputName() = 0;
    virtual const  size_t getModelDimCount() = 0;
    virtual const std::vector<int> getModelInputShape() = 0;
    virtual const std::string getClassLabelText(int classIndex) = 0;    

    static inline float sigmoid(float x) {
        return 1.f / (1.f + std::exp(-x));
    }

    static inline float linear(float x) {
        return x;
    }

    double intersectionOverUnion(const DetectedResult& o1, const DetectedResult& o2) {
        double overlappingWidth = std::fmin(o1.x + o1.width, o2.x + o2.width) - std::fmax(o1.x, o2.x);
        double overlappingHeight = std::fmin(o1.y + o1.height, o2.y + o2.height) - std::fmax(o1.y, o2.y);
        double intersectionArea = (overlappingWidth < 0 || overlappingHeight < 0) ? 0 : overlappingHeight * overlappingWidth;
        double unionArea = o1.width * o1.height + o2.width * o2.height - intersectionArea;
        return intersectionArea / unionArea;
    }

    virtual void postprocess(const int64_t* output_shape, const void* voutputData, const size_t bytesize, const uint32_t dimCount, std::vector<DetectedResult> &detectedResults)
    {
    }

    // Yolov5Ensemble detection/classification postprocess
    virtual void postprocess(
        const int64_t* output_shape_conf, const void* voutputData_conf, const size_t bytesize_conf, const uint32_t dimCount_conf, 
        const int64_t* output_shape_boxes, const void* voutputData_boxes, const size_t bytesize_boxes, const uint32_t dimCount_boxes, 
        const int64_t* output_shape_classification, const void* voutputData_classification, const size_t bytesize_classification, const uint32_t dimCount_classification,
        std::vector<DetectedResult> &detectedResults)
    {
        // derived to implement
    }

    // IOU postproc filter
    void postprocess(std::vector<DetectedResult> &detectedResults, std::vector<DetectedResult> &outDetectedResults)
    {

        if (useAdvancedPostprocessing) {
            // Advanced postprocessing
            // Checking IOU threshold conformance
            // For every i-th object we're finding all objects it intersects with, and comparing confidence
            // If i-th object has greater confidence than all others, we include it into result
            for (const auto& obj1 : detectedResults) {
                bool isGoodResult = true;
                for (const auto& obj2 : detectedResults) {
                    if (obj1.classId == obj2.classId && obj1.confidence < obj2.confidence &&
                        intersectionOverUnion(obj1, obj2) >= boxiou_threshold) {  // if obj1 is the same as obj2, condition
                                                                                // expression will evaluate to false anyway
                        isGoodResult = false;
                        break;
                    }
                }
                if (isGoodResult) {
                    outDetectedResults.push_back(obj1);
                }
            }
        } else {
            // Classic postprocessing
            std::sort(detectedResults.begin(), detectedResults.end(), [](const DetectedResult& x, const DetectedResult& y) {
                return x.confidence > y.confidence;
            });
            for (size_t i = 0; i < detectedResults.size(); ++i) {
                if (detectedResults[i].confidence == 0)
                    continue;
                for (size_t j = i + 1; j < detectedResults.size(); ++j)
                    if (intersectionOverUnion(detectedResults[i], detectedResults[j]) >= boxiou_threshold)
                        detectedResults[j].confidence = 0;
                outDetectedResults.push_back(detectedResults[i]);
            } //end for
        } // end if
    } // end postprocess IOU filter


protected:
    float confidence_threshold = .9;
    float boxiou_threshold = .4;
    float iou_threshold = 0.4;
    int classes =  80;
    bool useAdvancedPostprocessing = false;

};

class Yolov5Ensemble : public ObjectDetectionInterface {
public:

    Yolov5Ensemble() {
        confidence_threshold = _detection_threshold;
        classes = 1000;
        std::vector<int> vmodel_input_shape = getModelInputShape();
        std::copy(vmodel_input_shape.begin(), vmodel_input_shape.end(), model_input_shape);
    }

    const char* getModelName() {
        return MODEL_NAME;
    }

    const uint64_t getModelVersion() {
        return MODEL_VERSION;
    }

    const char* getModelInputName() {
        return INPUT_NAME;
    }

    const size_t getModelDimCount() {
        return MODEL_DIM_COUNT;
    }

    const std::vector<int> getModelInputShape() {
        std::vector<int> shape{1,3,416,416};
        return shape;
    }
    const std::string labels[1000] = {
        "tench, Tinca tinca",
        "goldfish, Carassius auratus",
        "great white shark, white shark, man-eater, man-eating shark, Carcharodon carcharias",
        "tiger shark, Galeocerdo cuvieri",
        "hammerhead, hammerhead shark",
        "electric ray, crampfish, numbfish, torpedo",
        "stingray",
        "cock",
        "hen",
        "ostrich, Struthio camelus",
        "brambling, Fringilla montifringilla",
        "goldfinch, Carduelis carduelis",
        "house finch, linnet, Carpodacus mexicanus",
        "junco, snowbird",
        "indigo bunting, indigo finch, indigo bird, Passerina cyanea",
        "robin, American robin, Turdus migratorius",
        "bulbul",
        "jay",
        "magpie",
        "chickadee",
        "water ouzel, dipper",
        "kite",
        "bald eagle, American eagle, Haliaeetus leucocephalus",
        "vulture",
        "great grey owl, great gray owl, Strix nebulosa",
        "European fire salamander, Salamandra salamandra",
        "common newt, Triturus vulgaris",
        "eft",
        "spotted salamander, Ambystoma maculatum",
        "axolotl, mud puppy, Ambystoma mexicanum",
        "bullfrog, Rana catesbeiana",
        "tree frog, tree-frog",
        "tailed frog, bell toad, ribbed toad, tailed toad, Ascaphus trui",
        "loggerhead, loggerhead turtle, Caretta caretta",
        "leatherback turtle, leatherback, leathery turtle, Dermochelys coriacea",
        "mud turtle",
        "terrapin",
        "box turtle, box tortoise",
        "banded gecko",
        "common iguana, iguana, Iguana iguana",
        "American chameleon, anole, Anolis carolinensis",
        "whiptail, whiptail lizard",
        "agama",
        "frilled lizard, Chlamydosaurus kingi",
        "alligator lizard",
        "Gila monster, Heloderma suspectum",
        "green lizard, Lacerta viridis",
        "African chameleon, Chamaeleo chamaeleon",
        "Komodo dragon, Komodo lizard, dragon lizard, giant lizard, Varanus komodoensis",
        "African crocodile, Nile crocodile, Crocodylus niloticus",
        "American alligator, Alligator mississipiensis",
        "triceratops",
        "thunder snake, worm snake, Carphophis amoenus",
        "ringneck snake, ring-necked snake, ring snake",
        "hognose snake, puff adder, sand viper",
        "green snake, grass snake",
        "king snake, kingsnake",
        "garter snake, grass snake",
        "water snake",
        "vine snake",
        "night snake, Hypsiglena torquata",
        "boa constrictor, Constrictor constrictor",
        "rock python, rock snake, Python sebae",
        "Indian cobra, Naja naja",
        "green mamba",
        "sea snake",
        "horned viper, cerastes, sand viper, horned asp, Cerastes cornutus",
        "diamondback, diamondback rattlesnake, Crotalus adamanteus",
        "sidewinder, horned rattlesnake, Crotalus cerastes",
        "trilobite",
        "harvestman, daddy longlegs, Phalangium opilio",
        "scorpion",
        "black and gold garden spider, Argiope aurantia",
        "barn spider, Araneus cavaticus",
        "garden spider, Aranea diademata",
        "black widow, Latrodectus mactans",
        "tarantula",
        "wolf spider, hunting spider",
        "tick",
        "centipede",
        "black grouse",
        "ptarmigan",
        "ruffed grouse, partridge, Bonasa umbellus",
        "prairie chicken, prairie grouse, prairie fowl",
        "peacock",
        "quail",
        "partridge",
        "African grey, African gray, Psittacus erithacus",
        "macaw",
        "sulphur-crested cockatoo, Kakatoe galerita, Cacatua galerita",
        "lorikeet",
        "coucal",
        "bee eater",
        "hornbill",
        "hummingbird",
        "jacamar",
        "toucan",
        "drake",
        "red-breasted merganser, Mergus serrator",
        "goose",
        "black swan, Cygnus atratus",
        "tusker",
        "echidna, spiny anteater, anteater",
        "platypus, duckbill, duckbilled platypus, duck-billed platypus, Ornithorhynchus anatinus",
        "wallaby, brush kangaroo",
        "koala, koala bear, kangaroo bear, native bear, Phascolarctos cinereus",
        "wombat",
        "jellyfish",
        "sea anemone, anemone",
        "brain coral",
        "flatworm, platyhelminth",
        "nematode, nematode worm, roundworm",
        "conch",
        "snail",
        "slug",
        "sea slug, nudibranch",
        "chiton, coat-of-mail shell, sea cradle, polyplacophore",
        "chambered nautilus, pearly nautilus, nautilus",
        "Dungeness crab, Cancer magister",
        "rock crab, Cancer irroratus",
        "fiddler crab",
        "king crab, Alaska crab, Alaskan king crab, Alaska king crab, Paralithodes camtschatica",
        "American lobster, Northern lobster, Maine lobster, Homarus americanus",
        "spiny lobster, langouste, rock lobster, crawfish, crayfish, sea crawfish",
        "crayfish, crawfish, crawdad, crawdaddy",
        "hermit crab",
        "isopod",
        "white stork, Ciconia ciconia",
        "black stork, Ciconia nigra",
        "spoonbill",
        "flamingo",
        "little blue heron, Egretta caerulea",
        "American egret, great white heron, Egretta albus",
        "bittern",
        "crane",
        "limpkin, Aramus pictus",
        "European gallinule, Porphyrio porphyrio",
        "American coot, marsh hen, mud hen, water hen, Fulica americana",
        "bustard",
        "ruddy turnstone, Arenaria interpres",
        "red-backed sandpiper, dunlin, Erolia alpina",
        "redshank, Tringa totanus",
        "dowitcher",
        "oystercatcher, oyster catcher",
        "pelican",
        "king penguin, Aptenodytes patagonica",
        "albatross, mollymawk",
        "grey whale, gray whale, devilfish, Eschrichtius gibbosus, Eschrichtius robustus",
        "killer whale, killer, orca, grampus, sea wolf, Orcinus orca",
        "dugong, Dugong dugon",
        "sea lion",
        "Chihuahua",
        "Japanese spaniel",
        "Maltese dog, Maltese terrier, Maltese",
        "Pekinese, Pekingese, Peke",
        "Shih-Tzu",
        "Blenheim spaniel",
        "papillon",
        "toy terrier",
        "Rhodesian ridgeback",
        "Afghan hound, Afghan",
        "basset, basset hound",
        "beagle",
        "bloodhound, sleuthhound",
        "bluetick",
        "black-and-tan coonhound",
        "Walker hound, Walker foxhound",
        "English foxhound",
        "redbone",
        "borzoi, Russian wolfhound",
        "Irish wolfhound",
        "Italian greyhound",
        "whippet",
        "Ibizan hound, Ibizan Podenco",
        "Norwegian elkhound, elkhound",
        "otterhound, otter hound",
        "Saluki, gazelle hound",
        "Scottish deerhound, deerhound",
        "Weimaraner",
        "Staffordshire bullterrier, Staffordshire bull terrier",
        "American Staffordshire terrier, Staffordshire terrier, American pit bull terrier, pit bull terrier",
        "Bedlington terrier",
        "Border terrier",
        "Kerry blue terrier",
        "Irish terrier",
        "Norfolk terrier",
        "Norwich terrier",
        "Yorkshire terrier",
        "wire-haired fox terrier",
        "Lakeland terrier",
        "Sealyham terrier, Sealyham",
        "Airedale, Airedale terrier",
        "cairn, cairn terrier",
        "Australian terrier",
        "Dandie Dinmont, Dandie Dinmont terrier",
        "Boston bull, Boston terrier",
        "miniature schnauzer",
        "giant schnauzer",
        "standard schnauzer",
        "Scotch terrier, Scottish terrier, Scottie",
        "Tibetan terrier, chrysanthemum dog",
        "silky terrier, Sydney silky",
        "soft-coated wheaten terrier",
        "West Highland white terrier",
        "Lhasa, Lhasa apso",
        "flat-coated retriever",
        "curly-coated retriever",
        "golden retriever",
        "Labrador retriever",
        "Chesapeake Bay retriever",
        "German short-haired pointer",
        "vizsla, Hungarian pointer",
        "English setter",
        "Irish setter, red setter",
        "Gordon setter",
        "Brittany spaniel",
        "clumber, clumber spaniel",
        "English springer, English springer spaniel",
        "Welsh springer spaniel",
        "cocker spaniel, English cocker spaniel, cocker",
        "Sussex spaniel",
        "Irish water spaniel",
        "kuvasz",
        "schipperke",
        "groenendael",
        "malinois",
        "briard",
        "kelpie",
        "komondor",
        "Old English sheepdog, bobtail",
        "Shetland sheepdog, Shetland sheep dog, Shetland",
        "collie",
        "Border collie",
        "Bouvier des Flandres, Bouviers des Flandres",
        "Rottweiler",
        "German shepherd, German shepherd dog, German police dog, alsatian",
        "Doberman, Doberman pinscher",
        "miniature pinscher",
        "Greater Swiss Mountain dog",
        "Bernese mountain dog",
        "Appenzeller",
        "EntleBucher",
        "boxer",
        "bull mastiff",
        "Tibetan mastiff",
        "French bulldog",
        "Great Dane",
        "Saint Bernard, St Bernard",
        "Eskimo dog, husky",
        "malamute, malemute, Alaskan malamute",
        "Siberian husky",
        "dalmatian, coach dog, carriage dog",
        "affenpinscher, monkey pinscher, monkey dog",
        "basenji",
        "pug, pug-dog",
        "Leonberg",
        "Newfoundland, Newfoundland dog",
        "Great Pyrenees",
        "Samoyed, Samoyede",
        "Pomeranian",
        "chow, chow chow",
        "keeshond",
        "Brabancon griffon",
        "Pembroke, Pembroke Welsh corgi",
        "Cardigan, Cardigan Welsh corgi",
        "toy poodle",
        "miniature poodle",
        "standard poodle",
        "Mexican hairless",
        "timber wolf, grey wolf, gray wolf, Canis lupus",
        "white wolf, Arctic wolf, Canis lupus tundrarum",
        "red wolf, maned wolf, Canis rufus, Canis niger",
        "coyote, prairie wolf, brush wolf, Canis latrans",
        "dingo, warrigal, warragal, Canis dingo",
        "dhole, Cuon alpinus",
        "African hunting dog, hyena dog, Cape hunting dog, Lycaon pictus",
        "hyena, hyaena",
        "red fox, Vulpes vulpes",
        "kit fox, Vulpes macrotis",
        "Arctic fox, white fox, Alopex lagopus",
        "grey fox, gray fox, Urocyon cinereoargenteus",
        "tabby, tabby cat",
        "tiger cat",
        "Persian cat",
        "Siamese cat, Siamese",
        "Egyptian cat",
        "cougar, puma, catamount, mountain lion, painter, panther, Felis concolor",
        "lynx, catamount",
        "leopard, Panthera pardus",
        "snow leopard, ounce, Panthera uncia",
        "jaguar, panther, Panthera onca, Felis onca",
        "lion, king of beasts, Panthera leo",
        "tiger, Panthera tigris",
        "cheetah, chetah, Acinonyx jubatus",
        "brown bear, bruin, Ursus arctos",
        "American black bear, black bear, Ursus americanus, Euarctos americanus",
        "ice bear, polar bear, Ursus Maritimus, Thalarctos maritimus",
        "sloth bear, Melursus ursinus, Ursus ursinus",
        "mongoose",
        "meerkat, mierkat",
        "tiger beetle",
        "ladybug, ladybeetle, lady beetle, ladybird, ladybird beetle",
        "ground beetle, carabid beetle",
        "long-horned beetle, longicorn, longicorn beetle",
        "leaf beetle, chrysomelid",
        "dung beetle",
        "rhinoceros beetle",
        "weevil",
        "fly",
        "bee",
        "ant, emmet, pismire",
        "grasshopper, hopper",
        "cricket",
        "walking stick, walkingstick, stick insect",
        "cockroach, roach",
        "mantis, mantid",
        "cicada, cicala",
        "leafhopper",
        "lacewing, lacewing fly",
        "dragonfly, darning needle, devil's darning needle, sewing needle, snake feeder, snake doctor, mosquito hawk, skeeter hawk",
        "damselfly",
        "admiral",
        "ringlet, ringlet butterfly",
        "monarch, monarch butterfly, milkweed butterfly, Danaus plexippus",
        "cabbage butterfly",
        "sulphur butterfly, sulfur butterfly",
        "lycaenid, lycaenid butterfly",
        "starfish, sea star",
        "sea urchin",
        "sea cucumber, holothurian",
        "wood rabbit, cottontail, cottontail rabbit",
        "hare",
        "Angora, Angora rabbit",
        "hamster",
        "porcupine, hedgehog",
        "fox squirrel, eastern fox squirrel, Sciurus niger",
        "marmot",
        "beaver",
        "guinea pig, Cavia cobaya",
        "sorrel",
        "zebra",
        "hog, pig, grunter, squealer, Sus scrofa",
        "wild boar, boar, Sus scrofa",
        "warthog",
        "hippopotamus, hippo, river horse, Hippopotamus amphibius",
        "ox",
        "water buffalo, water ox, Asiatic buffalo, Bubalus bubalis",
        "bison",
        "ram, tup",
        "bighorn, bighorn sheep, cimarron, Rocky Mountain bighorn, Rocky Mountain sheep, Ovis canadensis",
        "ibex, Capra ibex",
        "hartebeest",
        "impala, Aepyceros melampus",
        "gazelle",
        "Arabian camel, dromedary, Camelus dromedarius",
        "llama",
        "weasel",
        "mink",
        "polecat, fitch, foulmart, foumart, Mustela putorius",
        "black-footed ferret, ferret, Mustela nigripes",
        "otter",
        "skunk, polecat, wood pussy",
        "badger",
        "armadillo",
        "three-toed sloth, ai, Bradypus tridactylus",
        "orangutan, orang, orangutang, Pongo pygmaeus",
        "gorilla, Gorilla gorilla",
        "chimpanzee, chimp, Pan troglodytes",
        "gibbon, Hylobates lar",
        "siamang, Hylobates syndactylus, Symphalangus syndactylus",
        "guenon, guenon monkey",
        "patas, hussar monkey, Erythrocebus patas",
        "baboon",
        "macaque",
        "langur",
        "colobus, colobus monkey",
        "proboscis monkey, Nasalis larvatus",
        "marmoset",
        "capuchin, ringtail, Cebus capucinus",
        "howler monkey, howler",
        "titi, titi monkey",
        "spider monkey, Ateles geoffroyi",
        "squirrel monkey, Saimiri sciureus",
        "Madagascar cat, ring-tailed lemur, Lemur catta",
        "indri, indris, Indri indri, Indri brevicaudatus",
        "Indian elephant, Elephas maximus",
        "African elephant, Loxodonta africana",
        "lesser panda, red panda, panda, bear cat, cat bear, Ailurus fulgens",
        "giant panda, panda, panda bear, coon bear, Ailuropoda melanoleuca",
        "barracouta, snoek",
        "eel",
        "coho, cohoe, coho salmon, blue jack, silver salmon, Oncorhynchus kisutch",
        "rock beauty, Holocanthus tricolor",
        "anemone fish",
        "sturgeon",
        "gar, garfish, garpike, billfish, Lepisosteus osseus",
        "lionfish",
        "puffer, pufferfish, blowfish, globefish",
        "abacus",
        "abaya",
        "academic gown, academic robe, judge's robe",
        "accordion, piano accordion, squeeze box",
        "acoustic guitar",
        "aircraft carrier, carrier, flattop, attack aircraft carrier",
        "airliner",
        "airship, dirigible",
        "altar",
        "ambulance",
        "amphibian, amphibious vehicle",
        "analog clock",
        "apiary, bee house",
        "apron",
        "ashcan, trash can, garbage can, wastebin, ash bin, ash-bin, ashbin, dustbin, trash barrel, trash bin",
        "assault rifle, assault gun",
        "backpack, back pack, knapsack, packsack, rucksack, haversack",
        "bakery, bakeshop, bakehouse",
        "balance beam, beam",
        "balloon",
        "ballpoint, ballpoint pen, ballpen, Biro",
        "Band Aid",
        "banjo",
        "bannister, banister, balustrade, balusters, handrail",
        "barbell",
        "barber chair",
        "barbershop",
        "barn",
        "barometer",
        "barrel, cask",
        "barrow, garden cart, lawn cart, wheelbarrow",
        "baseball",
        "basketball",
        "bassinet",
        "bassoon",
        "bathing cap, swimming cap",
        "bath towel",
        "bathtub, bathing tub, bath, tub",
        "beach wagon, station wagon, wagon, estate car, beach waggon, station waggon, waggon",
        "beacon, lighthouse, beacon light, pharos",
        "beaker",
        "bearskin, busby, shako",
        "beer bottle",
        "beer glass",
        "bell cote, bell cot",
        "bib",
        "bicycle-built-for-two, tandem bicycle, tandem",
        "bikini, two-piece",
        "binder, ring-binder",
        "binoculars, field glasses, opera glasses",
        "birdhouse",
        "boathouse",
        "bobsled, bobsleigh, bob",
        "bolo tie, bolo, bola tie, bola",
        "bonnet, poke bonnet",
        "bookcase",
        "bookshop, bookstore, bookstall",
        "bottlecap",
        "bow",
        "bow tie, bow-tie, bowtie",
        "brass, memorial tablet, plaque",
        "brassiere, bra, bandeau",
        "breakwater, groin, groyne, mole, bulwark, seawall, jetty",
        "breastplate, aegis, egis",
        "broom",
        "bucket, pail",
        "buckle",
        "bulletproof vest",
        "bullet train, bullet",
        "butcher shop, meat market",
        "cab, hack, taxi, taxicab",
        "caldron, cauldron",
        "candle, taper, wax light",
        "cannon",
        "canoe",
        "can opener, tin opener",
        "cardigan",
        "car mirror",
        "carousel, carrousel, merry-go-round, roundabout, whirligig",
        "carpenter's kit, tool kit",
        "carton",
        "car wheel",
        "cash machine, cash dispenser, automated teller machine, automatic teller machine, automated teller, automatic teller, ATM",
        "cassette",
        "cassette player",
        "castle",
        "catamaran",
        "CD player",
        "cello, violoncello",
        "cellular telephone, cellular phone, cellphone, cell, mobile phone",
        "chain",
        "chainlink fence",
        "chain mail, ring mail, mail, chain armor, chain armour, ring armor, ring armour",
        "chain saw, chainsaw",
        "chest",
        "chiffonier, commode",
        "chime, bell, gong",
        "china cabinet, china closet",
        "Christmas stocking",
        "church, church building",
        "cinema, movie theater, movie theatre, movie house, picture palace",
        "cleaver, meat cleaver, chopper",
        "cliff dwelling",
        "cloak",
        "clog, geta, patten, sabot",
        "cocktail shaker",
        "coffee mug",
        "coffeepot",
        "coil, spiral, volute, whorl, helix",
        "combination lock",
        "computer keyboard, keypad",
        "confectionery, confectionary, candy store",
        "container ship, containership, container vessel",
        "convertible",
        "corkscrew, bottle screw",
        "cornet, horn, trumpet, trump",
        "cowboy boot",
        "cowboy hat, ten-gallon hat",
        "cradle",
        "crane",
        "crash helmet",
        "crate",
        "crib, cot",
        "Crock Pot",
        "croquet ball",
        "crutch",
        "cuirass",
        "dam, dike, dyke",
        "desk",
        "desktop computer",
        "dial telephone, dial phone",
        "diaper, nappy, napkin",
        "digital clock",
        "digital watch",
        "dining table, board",
        "dishrag, dishcloth",
        "dishwasher, dish washer, dishwashing machine",
        "disk brake, disc brake",
        "dock, dockage, docking facility",
        "dogsled, dog sled, dog sleigh",
        "dome",
        "doormat, welcome mat",
        "drilling platform, offshore rig",
        "drum, membranophone, tympan",
        "drumstick",
        "dumbbell",
        "Dutch oven",
        "electric fan, blower",
        "electric guitar",
        "electric locomotive",
        "entertainment center",
        "envelope",
        "espresso maker",
        "face powder",
        "feather boa, boa",
        "file, file cabinet, filing cabinet",
        "fireboat",
        "fire engine, fire truck",
        "fire screen, fireguard",
        "flagpole, flagstaff",
        "flute, transverse flute",
        "folding chair",
        "football helmet",
        "forklift",
        "fountain",
        "fountain pen",
        "four-poster",
        "freight car",
        "French horn, horn",
        "frying pan, frypan, skillet",
        "fur coat",
        "garbage truck, dustcart",
        "gasmask, respirator, gas helmet",
        "gas pump, gasoline pump, petrol pump, island dispenser",
        "goblet",
        "go-kart",
        "golf ball",
        "golfcart, golf cart",
        "gondola",
        "gong, tam-tam",
        "gown",
        "grand piano, grand",
        "greenhouse, nursery, glasshouse",
        "grille, radiator grille",
        "grocery store, grocery, food market, market",
        "guillotine",
        "hair slide",
        "hair spray",
        "half track",
        "hammer",
        "hamper",
        "hand blower, blow dryer, blow drier, hair dryer, hair drier",
        "hand-held computer, hand-held microcomputer",
        "handkerchief, hankie, hanky, hankey",
        "hard disc, hard disk, fixed disk",
        "harmonica, mouth organ, harp, mouth harp",
        "harp",
        "harvester, reaper",
        "hatchet",
        "holster",
        "home theater, home theatre",
        "honeycomb",
        "hook, claw",
        "hoopskirt, crinoline",
        "horizontal bar, high bar",
        "horse cart, horse-cart",
        "hourglass",
        "iPod",
        "iron, smoothing iron",
        "jack-o'-lantern",
        "jean, blue jean, denim",
        "jeep, landrover",
        "jersey, T-shirt, tee shirt",
        "jigsaw puzzle",
        "jinrikisha, ricksha, rickshaw",
        "joystick",
        "kimono",
        "knee pad",
        "knot",
        "lab coat, laboratory coat",
        "ladle",
        "lampshade, lamp shade",
        "laptop, laptop computer",
        "lawn mower, mower",
        "lens cap, lens cover",
        "letter opener, paper knife, paperknife",
        "library",
        "lifeboat",
        "lighter, light, igniter, ignitor",
        "limousine, limo",
        "liner, ocean liner",
        "lipstick, lip rouge",
        "Loafer",
        "lotion",
        "loudspeaker, speaker, speaker unit, loudspeaker system, speaker system",
        "loupe, jeweler's loupe",
        "lumbermill, sawmill",
        "magnetic compass",
        "mailbag, postbag",
        "mailbox, letter box",
        "maillot",
        "maillot, tank suit",
        "manhole cover",
        "maraca",
        "marimba, xylophone",
        "mask",
        "matchstick",
        "maypole",
        "maze, labyrinth",
        "measuring cup",
        "medicine chest, medicine cabinet",
        "megalith, megalithic structure",
        "microphone, mike",
        "microwave, microwave oven",
        "military uniform",
        "milk can",
        "minibus",
        "miniskirt, mini",
        "minivan",
        "missile",
        "mitten",
        "mixing bowl",
        "mobile home, manufactured home",
        "Model T",
        "modem",
        "monastery",
        "monitor",
        "moped",
        "mortar",
        "mortarboard",
        "mosque",
        "mosquito net",
        "motor scooter, scooter",
        "mountain bike, all-terrain bike, off-roader",
        "mountain tent",
        "mouse, computer mouse",
        "mousetrap",
        "moving van",
        "muzzle",
        "nail",
        "neck brace",
        "necklace",
        "nipple",
        "notebook, notebook computer",
        "obelisk",
        "oboe, hautboy, hautbois",
        "ocarina, sweet potato",
        "odometer, hodometer, mileometer, milometer",
        "oil filter",
        "organ, pipe organ",
        "oscilloscope, scope, cathode-ray oscilloscope, CRO",
        "overskirt",
        "oxcart",
        "oxygen mask",
        "packet",
        "paddle, boat paddle",
        "paddlewheel, paddle wheel",
        "padlock",
        "paintbrush",
        "pajama, pyjama, pj's, jammies",
        "palace",
        "panpipe, pandean pipe, syrinx",
        "paper towel",
        "parachute, chute",
        "parallel bars, bars",
        "park bench",
        "parking meter",
        "passenger car, coach, carriage",
        "patio, terrace",
        "pay-phone, pay-station",
        "pedestal, plinth, footstall",
        "pencil box, pencil case",
        "pencil sharpener",
        "perfume, essence",
        "Petri dish",
        "photocopier",
        "pick, plectrum, plectron",
        "pickelhaube",
        "picket fence, paling",
        "pickup, pickup truck",
        "pier",
        "piggy bank, penny bank",
        "pill bottle",
        "pillow",
        "ping-pong ball",
        "pinwheel",
        "pirate, pirate ship",
        "pitcher, ewer",
        "plane, carpenter's plane, woodworking plane",
        "planetarium",
        "plastic bag",
        "plate rack",
        "plow, plough",
        "plunger, plumber's helper",
        "Polaroid camera, Polaroid Land camera",
        "pole",
        "police van, police wagon, paddy wagon, patrol wagon, wagon, black Maria",
        "poncho",
        "pool table, billiard table, snooker table",
        "pop bottle, soda bottle",
        "pot, flowerpot",
        "potter's wheel",
        "power drill",
        "prayer rug, prayer mat",
        "printer",
        "prison, prison house",
        "projectile, missile",
        "projector",
        "puck, hockey puck",
        "punching bag, punch bag, punching ball, punchball",
        "purse",
        "quill, quill pen",
        "quilt, comforter, comfort, puff",
        "racer, race car, racing car",
        "racket, racquet",
        "radiator",
        "radio, wireless",
        "radio telescope, radio reflector",
        "rain barrel",
        "recreational vehicle, RV, R.V.",
        "reel",
        "reflex camera",
        "refrigerator, icebox",
        "remote control, remote",
        "restaurant, eating house, eating place, eatery",
        "revolver, six-gun, six-shooter",
        "rifle",
        "rocking chair, rocker",
        "rotisserie",
        "rubber eraser, rubber, pencil eraser",
        "rugby ball",
        "rule, ruler",
        "running shoe",
        "safe",
        "safety pin",
        "saltshaker, salt shaker",
        "sandal",
        "sarong",
        "sax, saxophone",
        "scabbard",
        "scale, weighing machine",
        "school bus",
        "schooner",
        "scoreboard",
        "screen, CRT screen",
        "screw",
        "screwdriver",
        "seat belt, seatbelt",
        "sewing machine",
        "shield, buckler",
        "shoe shop, shoe-shop, shoe store",
        "shoji",
        "shopping basket",
        "shopping cart",
        "shovel",
        "shower cap",
        "shower curtain",
        "ski",
        "ski mask",
        "sleeping bag",
        "slide rule, slipstick",
        "sliding door",
        "slot, one-armed bandit",
        "snorkel",
        "snowmobile",
        "snowplow, snowplough",
        "soap dispenser",
        "soccer ball",
        "sock",
        "solar dish, solar collector, solar furnace",
        "sombrero",
        "soup bowl",
        "space bar",
        "space heater",
        "space shuttle",
        "spatula",
        "speedboat",
        "spider web, spider's web",
        "spindle",
        "sports car, sport car",
        "spotlight, spot",
        "stage",
        "steam locomotive",
        "steel arch bridge",
        "steel drum",
        "stethoscope",
        "stole",
        "stone wall",
        "stopwatch, stop watch",
        "stove",
        "strainer",
        "streetcar, tram, tramcar, trolley, trolley car",
        "stretcher",
        "studio couch, day bed",
        "stupa, tope",
        "submarine, pigboat, sub, U-boat",
        "suit, suit of clothes",
        "sundial",
        "sunglass",
        "sunglasses, dark glasses, shades",
        "sunscreen, sunblock, sun blocker",
        "suspension bridge",
        "swab, swob, mop",
        "sweatshirt",
        "swimming trunks, bathing trunks",
        "swing",
        "switch, electric switch, electrical switch",
        "syringe",
        "table lamp",
        "tank, army tank, armored combat vehicle, armoured combat vehicle",
        "tape player",
        "teapot",
        "teddy, teddy bear",
        "television, television system",
        "tennis ball",
        "thatch, thatched roof",
        "theater curtain, theatre curtain",
        "thimble",
        "thresher, thrasher, threshing machine",
        "throne",
        "tile roof",
        "toaster",
        "tobacco shop, tobacconist shop, tobacconist",
        "toilet seat",
        "torch",
        "totem pole",
        "tow truck, tow car, wrecker",
        "toyshop",
        "tractor",
        "trailer truck, tractor trailer, trucking rig, rig, articulated lorry, semi",
        "tray",
        "trench coat",
        "tricycle, trike, velocipede",
        "trimaran",
        "tripod",
        "triumphal arch",
        "trolleybus, trolley coach, trackless trolley",
        "trombone",
        "tub, vat",
        "turnstile",
        "typewriter keyboard",
        "umbrella",
        "unicycle, monocycle",
        "upright, upright piano",
        "vacuum, vacuum cleaner",
        "vase",
        "vault",
        "velvet",
        "vending machine",
        "vestment",
        "viaduct",
        "violin, fiddle",
        "volleyball",
        "waffle iron",
        "wall clock",
        "wallet, billfold, notecase, pocketbook",
        "wardrobe, closet, press",
        "warplane, military plane",
        "washbasin, handbasin, washbowl, lavabo, wash-hand basin",
        "washer, automatic washer, washing machine",
        "water bottle",
        "water jug",
        "water tower",
        "whiskey jug",
        "whistle",
        "wig",
        "window screen",
        "window shade",
        "Windsor tie",
        "wine bottle",
        "wing",
        "wok",
        "wooden spoon",
        "wool, woolen, woollen",
        "worm fence, snake fence, snake-rail fence, Virginia fence",
        "wreck",
        "yawl",
        "yurt",
        "web site, website, internet site, site",
        "comic book",
        "crossword puzzle, crossword",
        "street sign",
        "traffic light, traffic signal, stoplight",
        "book jacket, dust cover, dust jacket, dust wrapper",
        "menu",
        "plate",
        "guacamole",
        "consomme",
        "hot pot, hotpot",
        "trifle",
        "ice cream, icecream",
        "ice lolly, lolly, lollipop, popsicle",
        "French loaf",
        "bagel, beigel",
        "pretzel",
        "cheeseburger",
        "hotdog, hot dog, red hot",
        "mashed potato",
        "head cabbage",
        "broccoli",
        "cauliflower",
        "zucchini, courgette",
        "spaghetti squash",
        "acorn squash",
        "butternut squash",
        "cucumber, cuke",
        "artichoke, globe artichoke",
        "bell pepper",
        "cardoon",
        "mushroom",
        "Granny Smith",
        "strawberry",
        "orange",
        "lemon",
        "fig",
        "pineapple, ananas",
        "banana",
        "jackfruit, jak, jack",
        "custard apple",
        "pomegranate",
        "hay",
        "carbonara",
        "chocolate sauce, chocolate syrup",
        "dough",
        "meat loaf, meatloaf",
        "pizza, pizza pie",
        "potpie",
        "burrito",
        "red wine",
        "espresso",
        "cup",
        "eggnog",
        "alp",
        "bubble",
        "cliff, drop, drop-off",
        "coral reef",
        "geyser",
        "lakeside, lakeshore",
        "promontory, headland, head, foreland",
        "sandbar, sand bar",
        "seashore, coast, seacoast, sea-coast",
        "valley, vale",
        "volcano",
        "ballplayer, baseball player",
        "groom, bridegroom",
        "scuba diver",
        "rapeseed",
        "daisy",
        "yellow lady's slipper, yellow lady-slipper, Cypripedium calceolus, Cypripedium parviflorum",
        "corn",
        "acorn",
        "hip, rose hip, rosehip",
        "buckeye, horse chestnut, conker",
        "coral fungus",
        "agaric",
        "gyromitra",
        "stinkhorn, carrion fungus",
        "earthstar",
        "hen-of-the-woods, hen of the woods, Polyporus frondosus, Grifola frondosa",
        "bolete",
        "ear, spike, capitulum",
        "toilet tissue, toilet paper, bathroom tissue"
    };

    const std::string getClassLabelText(int classIndex) {
        return labels[classIndex];
    }

    int argmax(const float* tensor, int numberElements) {
        float topConfidence = 0;
        int topLabel = -1;
        for (int i = 0; i < numberElements; i++) {
            float confidence = tensor[i];
            if (topLabel == -1 || topConfidence < confidence) {
                topLabel = i;
                topConfidence = confidence;
            }
        }
        return topLabel;
    }

    void postprocess(
        const int64_t* output_shape_conf, const void* voutputData_conf, const size_t bytesize_conf, const uint32_t dimCount_conf, 
        const int64_t* output_shape_boxes, const void* voutputData_boxes, const size_t bytesize_boxes, const uint32_t dimCount_boxes, 
        const int64_t* output_shape_classification, const void* voutputData_classification, const size_t bytesize_classification, const uint32_t dimCount_classification,
        std::vector<DetectedResult> &detectedResults)
    {
        if (!voutputData_boxes || !voutputData_conf || !voutputData_classification) {
            // nothing to do
            return;
        }

        if (dimCount_conf != 3 || dimCount_boxes != 3 || dimCount_classification != 3)
        {
            printf("Unknown yolov5 detection and/or efficientnet-b0 model.\n");
            return;
        }

        // Output Info
        // classify_output 1,1,1000
        // confidence -  1, 1, 1
        // boxes - 1,1,4
        const int numberOfDetections = output_shape_boxes[0];
        const int boxesSize = output_shape_boxes[2];
        const int* outData_boxes = reinterpret_cast<const int*>(voutputData_boxes);
        const float* outData_confidence = reinterpret_cast<const float*>(voutputData_conf);
        const float* outData_classify_labels = reinterpret_cast<const float*>(voutputData_classification);

        std::vector<int> input_shape = getModelInputShape();
        int network_h =  input_shape[2];
        int network_w =  input_shape[3];
        
        for (int i = 0; i < numberOfDetections; i++)
        {
            float confidence = outData_confidence[i];
            
            if (confidence > confidence_threshold ) {
                int classId = argmax(outData_classify_labels, output_shape_classification[2]);
                // printf("Confidence found: %f ClassID found: %i NetworkW %i NetworkH: %i BoxSize %i \n", confidence, classId, network_w, network_h, boxesSize);

                DetectedResult obj;
                obj.x = std::clamp(
                    static_cast<int>((outData_boxes[i * boxesSize + 0] / ((float)network_w / (float)_video_input_width))),
                     0, 
                     _video_input_width); 
                obj.y = std::clamp(
                    static_cast<int>((outData_boxes[i * boxesSize + 1] / ((float)network_h/(float)_video_input_height))), 
                    0, 
                    _video_input_height);
                obj.width = std::clamp(
                    static_cast<int>((outData_boxes[i * boxesSize + 2] / ((float)network_w/(float)_video_input_width)  )), 
                    0, 
                    _video_input_width); 
                obj.height = std::clamp(
                    static_cast<int>((outData_boxes[i * boxesSize + 3] / ((float)network_h/(float)_video_input_height) )), 
                    0, 
                    _video_input_height); 
                obj.confidence = confidence;
                obj.classId = (int) classId;
                strncpy(obj.classText, getClassLabelText(obj.classId).c_str(), sizeof(obj.classText));
                
                detectedResults.push_back(obj);
            } // end if confidence
        } // end for
    }

private:
    const char* MODEL_NAME = "detect_classify";
    const uint64_t MODEL_VERSION = 0;
    const char* INPUT_NAME = "images";
};



GStreamerMediaPipelineService* _mediaService = NULL;
std::string _user_request;

namespace {
volatile sig_atomic_t shutdown_request = 0;
}

bool stringIsInteger(std::string strInput) {
    std::string::const_iterator it = strInput.begin();
    while (it != strInput.end() && std::isdigit(*it)) ++it;
    return !strInput.empty() && it == strInput.end();
}

bool stringIsFloat(std::string strInput) {
    std::istringstream iss(strInput);
    float f;
    iss >> std::noskipws >> f; // noskipws considers leading whitespace invalid
    return iss.eof() && !iss.fail();
}

bool setActiveModel(int detectionType, ObjectDetectionInterface** objDet)
{
    if (objDet == NULL)
        return false;

    
    *objDet = new Yolov5Ensemble();     
    return true;
}

static void onInterrupt(int status) {
    shutdown_request = 1;
}

static void onTerminate(int status) {
    shutdown_request = 1;
}

static void onIllegal(int status) {
    shutdown_request = 2;
}

static void installSignalHandlers() {
    static struct sigaction sigIntHandler;
    sigIntHandler.sa_handler = onInterrupt;
    sigemptyset(&sigIntHandler.sa_mask);
    sigIntHandler.sa_flags = 0;
    sigaction(SIGINT, &sigIntHandler, NULL);

    static struct sigaction sigTermHandler;
    sigTermHandler.sa_handler = onTerminate;
    sigemptyset(&sigTermHandler.sa_mask);
    sigTermHandler.sa_flags = 0;
    sigaction(SIGTERM, &sigTermHandler, NULL);

    static struct sigaction sigIllHandler;
    sigIllHandler.sa_handler = onIllegal;
    sigemptyset(&sigIllHandler.sa_mask);
    sigIllHandler.sa_flags = 0;
    sigaction(SIGILL, &sigIllHandler, NULL);
}

void printInferenceResults(std::vector<DetectedResult> &results)
{
	for (auto & obj : results) {
	  std::cout << "Rect: [ " << obj.x << " , " << obj.y << " " << obj.width << ", " << obj.height << "] Class: " << obj.classText << "(" << obj.classId << ") Conf: " << obj.confidence << std::endl;
	}
}

void displayGUIInferenceResults(cv::Mat analytics_frame, std::vector<DetectedResult> &results, int latency, int througput)
{
    auto ttid = std::this_thread::get_id();
    std::stringstream ss;
    ss << ttid;
    std::string tid = ss.str();

    for (auto & obj : results) {
	    const float x0 = obj.x;
        const float y0 = obj.y;
        const float x1 = obj.x + obj.width;
        const float y1 = obj.y + obj.height;

        //printf("--------->coords: %f %f %f %f\n", x0, y0, x1, y1);
        cv::rectangle( analytics_frame,
            cv::Point( (int)(x0),(int)(y0) ),
            cv::Point( (int)x1, (int)y1 ),
            cv::Scalar(255, 0, 0),
            2, cv::LINE_8 );
        
        cv::Size textsize = cv::getTextSize(obj.classText, cv::FONT_HERSHEY_PLAIN, 1, 0,0);

        cv::rectangle(analytics_frame, 
            cv::Point( (int)(x0),(int)(y0-20) ), 
            cv::Point((int)x0 + textsize.width, (int)y0 + textsize.height), 
            CV_RGB(0, 0, 0), 
            -1);

        cv::putText(analytics_frame, 
            obj.classText, 
            cv::Size((int)x0, (int)y0), 
            cv::FONT_HERSHEY_PLAIN, 1, CV_RGB(255, 255, 255), 1);
        
    } // end for

    cv::Mat presenter;

    {
        std::lock_guard<std::mutex> lock(_drawingMtx);
        cv::imshow("OpenVINO Results " + tid, analytics_frame);
        cv::waitKey(1);
    }
}

void saveInferenceResultsAsVideo(cv::Mat &presenter, std::vector<DetectedResult> &results)
{
    for (auto & obj : results) {

        const float scaler_w = 416.0f/_video_input_width;
        const float scaler_h = 416.0f/_video_input_height;

        cv::rectangle( presenter,
         cv::Point( (int)(obj.x*scaler_w),(int)(obj.y*scaler_h) ),
         cv::Point( (int)((obj.x+obj.width) * scaler_w), (int)((obj.y+obj.height)*scaler_h) ),
         cv::Scalar(255, 0, 0),
         4, cv::LINE_8 );
  } // end for
  cv::imwrite("result.jpg", presenter);
}

// This function is responsible for generating a GST pipeline that
// decodes and resizes the video stream based on the desired window size or
// the largest analytics frame size needed if running headless
std::string getVideoPipelineText(std::string mediaPath, ObjectDetectionInterface* objDet, ObjectDetectionInterface* textDet)
{

    std::vector<int> modelFrameShape = objDet->getModelInputShape();
    if (textDet) {
        modelFrameShape = textDet->getModelInputShape();
    }

    int frame_width = modelFrameShape[3];
    int frame_height = modelFrameShape[2];

    if (_render)
    {
        frame_width = _window_width;
        frame_height = _window_height;
    }

    return _mediaService->getVideoDecodedPreProcessedPipeline(
        mediaPath,
        _videoType,
        frame_width,
        frame_height,
        _use_onevpl);
}

bool createModelServer()
{
    if (_srv == NULL)
        return false;

    OVMS_Status* res = OVMS_ServerStartFromConfigurationFile(_srv, _serverSettings, _modelsSettings);

    if (res) {
        uint32_t code = 0;
        const char* details = nullptr;

        OVMS_StatusCode(res, &code);
        OVMS_StatusDetails(res, &details);
        std::cerr << "ERROR: during start: code:" << code << "; details:" << details
                  << "; grpc_port: " << _server_grpc_port
                  << "; http_port: " << _server_http_port
                  << ";" << std::endl;

        OVMS_StatusDelete(res);

        if (_srv)
            OVMS_ServerDelete(_srv);

        if (_modelsSettings)
            OVMS_ModelsSettingsDelete(_modelsSettings);

        if (_serverSettings)
            OVMS_ServerSettingsDelete(_serverSettings);

        return false;
    }

    return true;
}

bool loadGStreamer(GstElement** pipeline,  GstElement** appsink, std::string mediaPath, ObjectDetectionInterface* _objDet)
{
    static int threadCnt = 0;

    std::string videoPipelineText = getVideoPipelineText(mediaPath, _objDet, NULL);
    std::cout << "--------------------------------------------------------------" << std::endl;
    std::cout << "Opening Media Pipeline: " << videoPipelineText << std::endl;
    std::cout << "--------------------------------------------------------------" << std::endl;

    *pipeline = gst_parse_launch (videoPipelineText.c_str(), NULL);
    if (*pipeline == NULL) {
        std::cout << "ERROR: Failed to parse GST pipeline. Quitting." << std::endl;
        return false;
    }

    std::string appsinkName = "appsink" + std::to_string(threadCnt++);

    *appsink = gst_bin_get_by_name (GST_BIN (*pipeline), appsinkName.c_str());

    // Check if all elements were created
    if (!(*appsink))
    {
        printf("ERROR: Failed to initialize GST pipeline (missing %s) Quitting.\n", appsinkName.c_str());
        return false;
    }

    GstStateChangeReturn gst_res;

    // Start pipeline so it could process incoming data
    gst_res = gst_element_set_state(*pipeline, GST_STATE_PLAYING);

    if (gst_res != GST_STATE_CHANGE_SUCCESS && gst_res != GST_STATE_CHANGE_ASYNC  ) {
        printf("ERROR: StateChange not successful. Error Code: %d\n", gst_res);
        return false;
    }

    return true;
}

// OVMS C-API is a global process (singleton design) wide server so can't create many of them
bool loadOVMS()
{
     OVMS_Status* res = NULL;     

     OVMS_ServerSettingsNew(&_serverSettings);
     OVMS_ModelsSettingsNew(&_modelsSettings);
     OVMS_ServerNew(&_srv);
     OVMS_ServerSettingsSetGrpcPort(_serverSettings, _server_grpc_port);
     OVMS_ServerSettingsSetRestPort(_serverSettings, _server_http_port);
     OVMS_ServerSettingsSetLogLevel(_serverSettings, OVMS_LOG_ERROR);

     char * ovmsCofigJsonFilePath = std::getenv("OVMS_MODEL_CONFIG_JSON");
     std::cout << "ovmsCofigJsonFilePath: "<<ovmsCofigJsonFilePath<<std::endl;
     if (ovmsCofigJsonFilePath == nullptr) {
        std::cout << "error: could not env OVMS_MODEL_CONFIG_JSON, so default it to config.json"<<std::endl;
        return false;
     }

     OVMS_ModelsSettingsSetConfigPath(_modelsSettings, ovmsCofigJsonFilePath);

     if (!createModelServer()) {
         std::cout << "Failed to create model server\n" << std::endl;
         return false;
     }
     else {
         std::cout << "--------------------------------------------------------------" << std::endl;
         std::cout << "Server ready for inference C-API ports " << _server_grpc_port << " " << _server_http_port << std::endl;
         std::cout << "--------------------------------------------------------------" << std::endl;
         _server_http_port+=1;
         _server_grpc_port+=1;
     }
     return true;
}

bool getMAPipeline(std::string mediaPath, GstElement** pipeline,  GstElement** appsink, ObjectDetectionInterface** _objDet)
{
    if (!setActiveModel(_detectorModel, _objDet)) {
        std::cout << "Unable to set active detection model" << std::endl;
        return false;
    }

    return loadGStreamer(pipeline, appsink, mediaPath, *_objDet);
}

void hwc_to_chw(cv::InputArray src, cv::OutputArray dst) {
  std::vector<cv::Mat> channels;
  cv::split(src, channels);

  for (auto &img : channels) {
    img = img.reshape(1, 1);
  }

  // Concatenate three vectors to one
  cv::hconcat( channels, dst );
}

void run_stream(std::string mediaPath, GstElement* pipeline, GstElement* appsink, ObjectDetectionInterface* objDet)
{
    auto ttid = std::this_thread::get_id();
    std::stringstream ss;
    ss << ttid;
    std::string tid = ss.str();

    // Wait for all decoder streams to init...otherwise causes a segfault when OVMS loads
    // https://stackoverflow.com/questions/48271230/using-condition-variablenotify-all-to-notify-multiple-threads
    std::unique_lock<std::mutex> lk(_mtx);
    _cvAllDecodersInitd.wait(lk, [] { return _allDecodersInitd;} );
    lk.unlock();

    printf("Starting thread: %s\n", tid.c_str()) ;

    auto initTime = std::chrono::high_resolution_clock::now();
    unsigned long numberOfFrames = 0;
    long long numberOfSkipFrames = 0;
    OVMS_Status* res = NULL;

    BarcodeProcessor barcode;

    while (!shutdown_request) {
        auto startTime = std::chrono::high_resolution_clock::now();

        // classify_output
        const void* voutputData1;
        size_t bytesize1 = 0;
        OVMS_DataType datatype1 = (OVMS_DataType)42;
        const int64_t* shape1{nullptr};
        size_t dimCount1 = 0;
        OVMS_BufferType bufferType1 = (OVMS_BufferType)42;
        uint32_t deviceId1 = 42;
        const char* outputName1{nullptr};

        // confidence_levels
        const void* voutputData2;
        size_t bytesize2 = 0;
        OVMS_DataType datatype2 = (OVMS_DataType)42;
        const int64_t* shape2{nullptr};
        size_t dimCount2 = 0;
        OVMS_BufferType bufferType2 = (OVMS_BufferType)42;
        uint32_t deviceId2 = 42;
        const char* outputName2{nullptr};

        // roi_coordinates
        const void* voutputData3;
        size_t bytesize3 = 0;
        OVMS_DataType datatype3 = (OVMS_DataType)42;
        const int64_t* shape3{nullptr};
        size_t dimCount3 = 0;
        OVMS_BufferType bufferType3 = (OVMS_BufferType)42;
        uint32_t deviceId3 = 42;
        const char* outputName3{nullptr};

        // Common across getoutput API
        uint32_t outputCount = 0;
        uint32_t outputId;
        
        GstSample *sample;
        GstStructure *s;
        GstBuffer *buffer;
        GstMapInfo m;

        std::vector<DetectedResult> detectedResults;
        std::vector<DetectedResult> detectedResultsFiltered;

        auto metricStartTime = std::chrono::high_resolution_clock::now();
        if (gst_app_sink_is_eos(GST_APP_SINK(appsink))) {
            std::cout << "INFO: EOS " << std::endl;
            return;
        }
        auto metricEndTime = std::chrono::high_resolution_clock::now();
        auto metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
        //cout << "Get appsink latency (ms): " << metricLatencyTime << endl;

        metricStartTime = std::chrono::high_resolution_clock::now();
        sample = gst_app_sink_try_pull_sample (GST_APP_SINK(appsink), 50 * GST_SECOND);        

        if (sample == nullptr) {
            std::cout << "ERROR: No sample found" << std::endl;
            return;
        }
        metricEndTime = std::chrono::high_resolution_clock::now();
        metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
        //cout << "Pull sample latency (ms): " << metricLatencyTime << endl;

        GstCaps *caps;
        caps = gst_sample_get_caps(sample);

        if (caps == nullptr) {
            std::cout << "ERROR: No caps found for sample" << std::endl;
            return;
        }

        s = gst_caps_get_structure(caps, 0);
        gst_structure_get_int(s, "width", &_video_input_width);
        gst_structure_get_int(s, "height", &_video_input_height);

        metricStartTime = std::chrono::high_resolution_clock::now();
        buffer = gst_sample_get_buffer(sample);
        metricEndTime = std::chrono::high_resolution_clock::now();
        metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
        //cout << "Get sample buffer latency (ms): " << metricLatencyTime << endl;

        metricStartTime = std::chrono::high_resolution_clock::now();
        gst_buffer_map(buffer, &m, GST_MAP_READ);
        metricEndTime = std::chrono::high_resolution_clock::now();
        metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
        //cout << "Copy sample buffer latency (ms): " << metricLatencyTime << endl;

        if (m.size <= 0) {
            std::cout << "ERROR: Invalid buffer size" << std::endl;
            return;
        }

        cv::Mat analytics_frame;
        cv::Mat floatImage;
        std::vector<int> inputShape;

        inputShape = objDet->getModelInputShape();

        metricStartTime = std::chrono::high_resolution_clock::now();
        cv::Mat img(_video_input_height, _video_input_width, CV_8UC3, (void *) m.data);
        metricEndTime = std::chrono::high_resolution_clock::now();
        metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());

        // When rendering is enabled then the input frame is resized to window size and not the needed model input size
        if (_render) {
            
            if (dynamic_cast<const Yolov5Ensemble*>(objDet) != nullptr)
	        {
                metricStartTime = std::chrono::high_resolution_clock::now();
                resize(img, analytics_frame, cv::Size(inputShape[2], inputShape[3]), 0, 0, cv::INTER_LINEAR);
                metricEndTime = std::chrono::high_resolution_clock::now();
                metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
                metricStartTime = std::chrono::high_resolution_clock::now();
		        hwc_to_chw(analytics_frame, analytics_frame);
                metricEndTime = std::chrono::high_resolution_clock::now();
                metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
	        }
            else
	        {
                printf("ERROR: Unknown model type\n");
		        return;
	        }
            metricStartTime = std::chrono::high_resolution_clock::now();
	        analytics_frame.convertTo(floatImage, CV_32F);
            metricEndTime = std::chrono::high_resolution_clock::now();
            metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());
        }
        else {
            hwc_to_chw(img, analytics_frame);
            analytics_frame.convertTo(floatImage, CV_32F);
        }

        const int DATA_SIZE = floatImage.step[0] * floatImage.rows;

	    OVMS_InferenceResponse* response = nullptr;
        OVMS_InferenceRequest* request{nullptr};

        // OD Inference
        {            
            std::lock_guard<std::mutex> lock(_infMtx);

            metricStartTime = std::chrono::high_resolution_clock::now();

            OVMS_InferenceRequestNew(&request, _srv, objDet->getModelName(), objDet->getModelVersion());

            OVMS_InferenceRequestAddInput(
                request,
                objDet->getModelInputName(),
                OVMS_DATATYPE_FP32,
                objDet->model_input_shape,
                objDet->getModelDimCount()
            );

            // run sync request
            OVMS_InferenceRequestInputSetData(
                request,
                objDet->getModelInputName(),
                reinterpret_cast<void*>(floatImage.data),
                DATA_SIZE ,
                OVMS_BUFFERTYPE_CPU,
                0
            );

            res = OVMS_Inference(_srv, request, &response);

            metricEndTime = std::chrono::high_resolution_clock::now();
            metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());

            if (res != nullptr) {
                uint32_t code = 0;
                const char* details = 0;
                OVMS_StatusCode(res, &code);
                OVMS_StatusDetails(res, &details);                

                OVMS_StatusDelete(res);
                if (request)
                    OVMS_InferenceRequestDelete(request);

                metricStartTime = std::chrono::high_resolution_clock::now();

                gst_buffer_unmap(buffer, &m);
                gst_sample_unref(sample);

                metricEndTime = std::chrono::high_resolution_clock::now();
                metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());

                if (code != 176 /*ovms::StatusCode::PIPELINE_DEMULTIPLEXER_NO_RESULTS*/)
                {
                    std::cout << "Error occured during inference. Code:" << code << std::endl;
                    std::cout << ", details:" << details << std::endl;
                    break;
                }
                else
                    continue;                
            }
        } // end lock on inference request to server        

        // Barcode detect and decode
        if(_barcode == 1){
            barcode.decode(img);
        }        

        metricStartTime = std::chrono::high_resolution_clock::now();
        OVMS_InferenceResponseOutputCount(response, &outputCount);
        outputId = 0;

        // confidence_levels        
        OVMS_InferenceResponseOutput(response, outputId, &outputName1, &datatype1, &shape1, &dimCount1, &voutputData1, &bytesize1, &bufferType1, &deviceId1);

        // roi_coordinates
        outputId = 1;
        OVMS_InferenceResponseOutput(response, outputId, &outputName2, &datatype2, &shape2, &dimCount2, &voutputData2, &bytesize2, &bufferType2, &deviceId2);

        // classify_output e.g. Classification results
        outputId = 2;
        OVMS_InferenceResponseOutput(response, outputId, &outputName3, &datatype3, &shape3, &dimCount3, &voutputData3, &bytesize3, &bufferType3, &deviceId3);

        objDet->postprocess(
            shape1, voutputData1, bytesize1, dimCount1, 
            shape2, voutputData2, bytesize2, dimCount2, 
            shape3, voutputData3, bytesize3, dimCount3, 
            detectedResults);
        objDet->postprocess(detectedResults, detectedResultsFiltered);

        metricEndTime = std::chrono::high_resolution_clock::now();
        metricLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(metricEndTime-metricStartTime)).count());

        numberOfSkipFrames++;
        float fps = 0;
        if (numberOfSkipFrames <= 120) // allow warm up for latency/fps measurements
        {
            initTime = std::chrono::high_resolution_clock::now();
            numberOfFrames = 0;

            //printf("Too early...Skipping frames..\n");
        }
        else
        {
            numberOfFrames++;

            auto endTime = std::chrono::high_resolution_clock::now();            
            auto latencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(endTime-startTime)).count());
            auto runningLatencyTime = ((std::chrono::duration_cast<std::chrono::milliseconds>(endTime-initTime)).count());
            if (runningLatencyTime > 0) { // skip a few to account for init
                fps = (float)numberOfFrames/(float)(runningLatencyTime/1000); // convert to seconds
            }
    
            if (_render)
                displayGUIInferenceResults(img, detectedResultsFiltered, latencyTime, fps);

            static int highest_latency_frame = 0;
            static int lowest_latency_frame = 9999;
            static int avg_latency_frame = 0;
            static int total_latency_frames = 0;

            int frame_latency = chrono::duration_cast<chrono::milliseconds>(endTime - startTime).count();
            
            if (frame_latency > highest_latency_frame)
                highest_latency_frame = frame_latency;
            if (frame_latency < lowest_latency_frame)
                lowest_latency_frame = frame_latency;
            
            total_latency_frames += frame_latency;
            


            if (numberOfFrames % 30 == 0) {
                avg_latency_frame = total_latency_frames / 30;

                time_t     currTime = time(0);
                struct tm  tstruct;
                char       bCurrTime[80];
                tstruct = *localtime(&currTime);
                // http://en.cppreference.com/w/cpp/chrono/c/strftime
                strftime(bCurrTime, sizeof(bCurrTime), "%Y-%m-%d.%X", &tstruct);

                cout << detectedResultsFiltered.size() << " object(s) detected at " << bCurrTime  << endl;
                cout << "Avg. Pipeline Throughput FPS: " << ((isinf(fps)) ? "..." : std::to_string(fps)) << endl;
                cout << "Avg. Pipeline Latency (ms): " << avg_latency_frame << endl;
                cout << "Max. Pipeline Latency (ms): " << highest_latency_frame << endl;
                cout << "Min. Pipeline Latency (ms): " << lowest_latency_frame << endl;
                highest_latency_frame = 0;
                lowest_latency_frame = 9999;
                total_latency_frames = 0;
            }

        }

        if (request) {
           OVMS_InferenceRequestInputRemoveData(request, objDet->getModelInputName()); // doesn't help
           OVMS_InferenceRequestRemoveInput(request, objDet->getModelInputName());
           OVMS_InferenceRequestDelete(request);
        }

        if (response) {
           OVMS_InferenceResponseDelete(response);
        }

        gst_buffer_unmap(buffer, &m);
        gst_sample_unref(sample);

        if (shutdown_request > 0)
            break;
    } // end while get frames

    std::cout << "Goodbye..." << std::endl;

    if (res != NULL) {
        OVMS_StatusDelete(res);
        res = NULL;
    }

    if (objDet) {
        delete objDet;
        objDet = NULL;
    }

    gst_element_set_state (pipeline, GST_STATE_NULL);
    if (pipeline)
        gst_object_unref(pipeline);

    if (appsink)
        gst_object_unref(appsink);
}

void print_usage(const char* programName) {
    std::cout << "Usage: ./" << programName << " \n\n"
        << "mediaLocation is an rtsp://127.0.0.1:8554/camera_0 url or a path to an *.mp4 file\n"
        << "use_onevpl is 0 (libva - default) or 1 for onevpl\n"
        << "render is 1 to launch render window or 0 (default) for headless\n"
        << "video_type is 0 for AVC or 1 for HEVC\n"
        << "window_width is display window width\n"
        << "window_height is display window height\n"
        << "detection_threshold is confidence threshold value in floating point that needs to be between 0.0 to 1.0\n";
}

int get_running_servers() {
    const char * val = std::getenv("cid_count");
    std::cout << "val: "<<val<<std::endl;
    if ( val == nullptr ) {
        std::cout << "Got null for env variable cid_count, so default it to 0. "<<std::endl;
         return 0;
     }
     else {
         return std::stoi(val);
     }
}

int main(int argc, char** argv) {
    std::cout << std::setprecision(2) << std::fixed;

    // Use GST pipelines for media HWA decode and pre-procesing
    _mediaService = new GStreamerMediaPipelineService();

    // get valid server port numbers
    int running_servers = get_running_servers();
    _server_grpc_port = 9178 + running_servers;
    _server_http_port = 11338 + running_servers;

    _videoStreamPipeline = "people-detection.mp4";

    if (argc < 9) {
        print_usage(argv[0]);
        return 1;
    }

    if (!stringIsInteger(argv[2]) || !stringIsInteger(argv[3]) || !stringIsInteger(argv[4])
        || !stringIsInteger(argv[5]) || !stringIsInteger(argv[6]) || !stringIsInteger(argv[7]) || !stringIsFloat(argv[8])) {
        print_usage(argv[0]);
        return 1;
    } else {
        _videoStreamPipeline = argv[1];
        std::cout << "_videoStreamPipeline: " << _videoStreamPipeline << std::endl;
        _use_onevpl = std::stoi(argv[2]);
        std::cout << "_use_onevpl: " << _use_onevpl << std::endl;
        _render = std::stoi(argv[3]);
        std::cout << "_render: " << _render << std::endl;
        _renderPortrait = std::stoi(argv[4]);
        std::cout << "_renderPortrait: " << _renderPortrait << std::endl;
        _videoType = (MediaPipelineServiceInterface::VIDEO_TYPE) std::stoi(argv[5]);
        std::cout << "argv[5]: " << argv[5] << std::endl;
        _window_width = std::stoi(argv[6]);
        _window_height = std::stoi(argv[7]);
        std::cout << "_window_width: " << _window_width << std::endl;
        std::cout << "_window_height: " << _window_height << std::endl;
        _detection_threshold=std::stof(argv[8]);
        if (_detection_threshold > 1.0 || _detection_threshold < 0.0) {
            std::cout << "detection_threshold: " << _detection_threshold << ", is confidence threshold value in floating point that needs to be between 0.0 to 1.0.\n" << endl;
            return 1;
        }
         _barcode = std::stoi(argv[9]);
        std::cout << "_barcode: " << _barcode << std::endl;

        if (_renderPortrait) {
            int tmp = _window_width;
            _window_width = _window_height;
            _window_height = tmp;
        }
    }

    gst_init(NULL, NULL);

    std::vector<std::thread> running_streams;
    _allDecodersInitd = false;
    
    GstElement *pipeline;
    GstElement *appsink;
    ObjectDetectionInterface* objDet;
    getMAPipeline(_videoStreamPipeline, &pipeline,  &appsink, &objDet);
    running_streams.emplace_back(run_stream, _videoStreamPipeline, pipeline, appsink, objDet);

    if (!loadOVMS())
        return -1;

    _allDecodersInitd = true;
    _cvAllDecodersInitd.notify_all();;

    
   for(auto& running_stream : running_streams)
       running_stream.join();

    if (_mediaService != NULL) {
        delete _mediaService;
        _mediaService = NULL;
    }

    if (_srv)
        OVMS_ServerDelete(_srv);
    if (_modelsSettings)
        OVMS_ModelsSettingsDelete(_modelsSettings);
    if (_serverSettings)
        OVMS_ServerSettingsDelete(_serverSettings);

    return 0;
}
