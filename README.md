# Automated Self Checkout

![CodeQL](https://github.com/intel-retail/automated-self-checkout/actions/workflows/codeql.yaml/badge.svg?branch=main) ![Trivy](https://github.com/intel-retail/automated-self-checkout/actions/workflows/trivy-scan.yaml/badge.svg?branch=main) ![GolangTest](https://github.com/intel-retail/automated-self-checkout/actions/workflows/gotest.yaml/badge.svg?branch=main) ![DockerImageBuild](https://github.com/intel-retail/automated-self-checkout/actions/workflows/build.yaml/badge.svg?branch=main)  [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/intel-retail/automated-self-checkout/badge)](https://api.securityscorecards.dev/projects/github.com/intel-retail/automated-self-checkout)

[Documentation](https://intel-retail.github.io/automated-self-checkout/)

## Known issues

- Once barcode is detected and decoded, barcode label text is displayed inside the object even if barcode is not visible.
- Overlapping object detection label (gvatrack adds its own labels)

## Disclaimer

GStreamer is an open source framework licensed under LGPL. See https://gstreamer.freedesktop.org/documentation/frequently-asked-questions/licensing.html?gi-language=c.  You are solely responsible for determining if your use of Gstreamer requires any additional licenses.  Intel is not responsible for obtaining any such licenses, nor liable for any licensing fees due, in connection with your use of Gstreamer.

Certain third-party software or hardware identified in this document only may be used upon securing a license directly from the third-party software or hardware owner. The identification of non-Intel software, tools, or services in this document does not constitute a sponsorship, endorsement, or warranty by Intel.

## Datasets & Models Disclaimer:

To the extent that any data, datasets or models are referenced by Intel or accessed using tools or code on this site such data, datasets and models are provided by the third party indicated as the source of such content. Intel does not create the data, datasets, or models, provide a license to any third-party data, datasets, or models referenced, and does not warrant their accuracy or quality.  By accessing such data, dataset(s) or model(s) you agree to the terms associated with that content and that your use complies with the applicable license.

Intel expressly disclaims the accuracy, adequacy, or completeness of any data, datasets or models, and is not liable for any errors, omissions, or defects in such content, or for any reliance thereon. Intel also expressly disclaims any warranty of non-infringement with respect to such data, dataset(s), or model(s). Intel is not liable for any liability or damages relating to your use of such data, datasets or models.
