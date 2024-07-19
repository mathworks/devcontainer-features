# MATLAB Feature for Development Containers


Use the [MATLAB Feature](./src/matlab/README.md) in this repository to add MATLAB&reg;, Simulink&reg;, and other MathWorks&trade; products to your development containers. 

For more information about running MATLAB in dev containers, see 
[Run MATLAB in GitHub&trade; Codespaces](https://github.com/mathworks-ref-arch/matlab-codespaces). 


## Get Started

A development container [Feature (GitHub)](https://github.com/devcontainers/features/) is self-contained code you can use to add functionality to your development container. You can add a feature to your development container by modifying `devcontainer.json`, the configuration file of the container. For instructions on creating a development container and adding a feature, see [Create a Dev Container (VS Code Docs)](https://code.visualstudio.com/docs/devcontainers/create-dev-container).


Use the [MATLAB Feature](./src/matlab/README.md) to:

* Install the [system dependencies](https://github.com/mathworks-ref-arch/container-images/tree/main/matlab-deps) required to run MATLAB and other MathWorks products.
* Install MATLAB and other MathWorks products using [MATLAB Package Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md).
* Add MATLAB to the system PATH.
* Install Python packages such as the [MATLAB Engine for Python](https://github.com/mathworks/matlab-engine-for-python), [MATLAB Proxy](https://github.com/mathworks/matlab-proxy), and [MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy).

### Usage

To use the MATLAB Feature, include it in your dev container by specifying the `devcontainer.json` configuration file with your desired MATLAB Feature [Options](./src/matlab/README.md#options).

For example, to install MATLAB `R2024a` with Symbolic Math Toolbox in a `ubuntu` base image, use this `devcontainer.json` configuration:

```json
{
    "image": "ubuntu:latest",
    "features": {
        "ghcr.io/mathworks/devcontainer-features/matlab:0": {
            "release": "r2024a",
            "products": "MATLAB Symbolic_Math_Toolbox"
        }
    }
}
```
This configuration installs MATLAB R2024a in your dev container and adds the `matlab` executable to your PATH.


## Related Links

Codespaces:
* [Run MATLAB in GitHub Codespaces (GitHub)](https://github.com/mathworks-ref-arch/matlab-codespaces)
* [Overview of Codespaces (GitHub)](https://docs.github.com/en/codespaces/overview)

Dev Containers:
* [Create a Dev Container (VS Code Docs)](https://code.visualstudio.com/docs/devcontainers/create-dev-container)
* [Dev Container Metadata Reference](https://containers.dev/implementors/json_reference/)

Dev Container Features:
* [Dev Container Features (GitHub)](https://github.com/devcontainers/features/)
* [Dev Container Features Specification](https://containers.dev/implementors/features/)
* [Dev Container Feature JSON Properties](https://containers.dev/implementors/features/#devcontainer-json-properties)




----

Copyright 2024 The MathWorks, Inc.

----