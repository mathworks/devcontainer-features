
# MATLAB (matlab)

Installs MATLAB with supporting packages and tools.

## Example Usage

```json
"features": {
    "ghcr.io/mathworks/devcontainer-features/matlab:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| release | MATLAB Release to install. | string | r2024a |
| products | Products to install, specified as a list of space-separated product names.</br> For details of products, see [MATLAB Package Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md#product-installation-options). | string | MATLAB |
| doc | Flag to install documentation and examples (R2022b and earlier releases). | boolean | false |
| installGpu | Skips installation of GPU libraries when you install Parallel Computing Toolbox (R2023a and later releases). | boolean | false |
| destination | Full path to the installation destination folder. | string | /opt/matlab/$RELEASE |
| installMatlabProxy | Installs matlab-proxy and its dependencies (R2020b and later releases). | boolean | false |
| installJupyterMatlabProxy | Installs jupyter-matlab-proxy and its dependencies (R2020b and later releases). | boolean | false |
| installMatlabEngineForPython | Installs the MATLAB Engine for Python if the destination option is set correctly. | boolean | false |
| startInDesktop | Starts matlab-proxy when container starts. | string | false |
| networkLicenseManager | MATLAB will use the specified Network License Manager. | string | - |
| skipMATLABInstall | Set to true if you do not want to install MATLAB, for example if you only want to install `matlab-proxy` or `jupyter-matlab-proxy`. | boolean | false |

## Customizations

### VS Code Extensions

- `MathWorks.language-matlab`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mathworks/devcontainer-features/blob/main/src/matlab/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
