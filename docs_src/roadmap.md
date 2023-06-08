# Roadmap

  
  <table>
<thead>
  <tr>
    <th>Roadmap Timeline</th>
    <th>Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td><strong>Now</strong>
      <ul>
        <li><strong>Computer Vision Pipeline</strong><br>
            A single service that processes a streaming video and runs inferencing across products placed on a self-checkout station.</li>
        <li><strong>Benchmark Script</strong><br>
          A script that allows the end user to reproduce our benchmark results. The script provides capabilities to run benchmarks on partner models.</li>
        <li><strong>Benchmark Results</strong><br>
          Detailed benchmark results across GPU, CPU and GPU hardware SKUs</li>
      </ul>
    </td>
    <td rowspan="3" valign="top">
      <p><strong>Context</strong></p>
      <p>Automation is rapidly becoming the key transformational strategy for retailers. Age old problems such as inventory control, planogram compliance, store security, store operations, warehousing are areas that can benefit from automation that is predominantly driven by computer vision and AI. Whilst computer vision-based solutions exist for many of these problems, not many have moved beyond pilots and scaled across supermarkets due to various technical and business reasons. We are looking to address the use of computer vision across a multiple set of use cases in the retail space. The first of these use cases will be to help address the scalability of vision enabled self-checkout solutions. This will be followed by use cases such as Loss Prevention, AI assisted Shopping Carts, Autonomous Stores and many more in the future as the retail landscape evolves. The goal of this roadmap is to provide key ingredients and easy decision making to our partners on their journey to build and deploy these use cases at scale.</p>
      <p><strong>High-level Focus</strong></p>
        Vision enabled use cases will need to address four fundamental areas to build and deploy solutions at scale.
        <ul>
          <li>Camera Management<br>
          Cameras are a critical piece of the infrastructure, providing both video streams and images to be used across these use cases. We will be focusing on providing a consistent mechanism of onboarding different types of cameras and managing its lifecycle.</li>         <li>Computer Vision Pipeline<br>
          Workload deployment options and choices of frameworks makes the vision pipeline complex. We will focus our breaking down the pipeline into its individual services and making it easier to deploy and run across distributed architecture.</li>
         <li>Hardware Recommendation</br>
          There are many unknowns when moving from a pilot to production and especially during the scale phase of the project. For every use case, it is important to know exactly what infrastructure is required to deploy and scale the solution.
          We plan to remove all the guess work around what hardware is required to run these workloads.</li>
          <li> Deployment with ISVs </br>
          The time taken to operationalize new AI-based software in a new environment is often long. Working with our partners, we would focus our efforts in reducing the time to production.</li>
        </ul>
      </p>
     <p><strong>Out-of-Scope</strong></p>
      There are several items that will not be considered as part of this reference implementation. This is not an exhaustive list, but these are core exclusions as they are not our differentiators:
      <ul>
         <li>We will not build or recommend AI models</li>
         <li>We will not build end-to-end solutions</li>
         <li>We will not advocate for a specific software deployment architecture</li>
      </ul>   
    </td>
  </tr>
  <tr>
    <td><strong>Next</strong>
      <ul>
        <li><strong>Distributed Architecture</strong><br>
        Separating out media pre-processing, AI inferencing and post-processing as completely independent services. Providing a mechanism to deploy and run the individual services across distributed heterogeneous compute. Publish all events to an Enterprise Service Bus (ESB).</li>
        <li><strong>Update Benchmark script</strong><br>
        Update the script to reflect the new distributed architecture.</li>
        <li><strong>Benchmark Results</strong><br>
        Benchmark results across CPU and GPU and GPU only hardware SKUs (previous results updated and new SKUs added)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td><strong>Later</strong>
      <ul>
        <li><strong>Model Drift and updates</strong><br>
        Monitor model accuracy and rectify model drift. Add new models in live systems.</li>
        <li><strong>Edge Training</strong>
        Provide a mechanism to do localized instore training to ensure new products are identified without delay.</li>
        <li><strong>Hierarchical model support</strong><br>
        Provide a mechanism to have a hierarchy of models that gets chosen and executed based on initial segmentation.</li>
        <li><strong>Dev Cloud Support</strong><br>
        Provide a cloud environment for partners to access the hardware and run benchmarks.</li>
        <li><strong>Camera Management</strong><br>
        Provide a mechanism to onboard and drive the camera lifecycle across the store.</li>
      </ul>
    </td>
  </tr>
</tbody>
</table>

**Disclaimer**: The roadmap is for informational purposes only and is subject to change.
  
**Help Drive Our Roadmap Priorities**
We want to drive our roadmap by building the most valuable assets/ingredients to our partners. Our roadmap will be public and will provide complete transparency to ensure we receive continuous feedback from our partners. Raise any issues and requirements to help us guide our roadmap priorities, and in doing so we can drive the retail vertical forward. 

Open an [issue on GitHub](https://github.com/intel-retail/automated-self-checkout/issues) to report a problem or to provide feedback.


