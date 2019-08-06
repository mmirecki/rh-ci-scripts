# rh-ci-scripts

Various CI scripts

#rh-update-container-yaml

Updates the container.yaml file with an upstream source section similar to:


```
go:
    modules:
     -  module: github.com/kubevirt/bridge-marker
```

List of projects to update is taken from the projects file.
The format of the projects file is as follows:
```
<repo>  <optionally: u/s repo>
...
```

for example:
```
bridge-marker
kubemacpool   github.com/K8sNetworkPlumbingWG/kubemacpool
```

If the optional u/s repo is not specified, the script will attempt
to retrieve it from the rh-manifest file, if this fails, the repo will not
be updated.

