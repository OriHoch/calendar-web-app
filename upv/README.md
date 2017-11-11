## What is upv?

`upv` is a framework that enables modularity and reusability of code, documentation and best practices.

It provides a minimal common layer, combined with tools, conventions and best practices.

## upv objectives

Optimize the following processes:

* *POC* - turning an abstract idea to concrete POC implementation or research
* *Implementation* - Converting the POC to a concrete stable, deployable implementation
* *Scale* - Scaling up the implementation to handle higher load / data / change requirements
* *Support* - Supporting the project in the long-term - project management, monitoring, alerts, etc..

## Upv concepts and tools

* `./upv.sh`
  * the main entrypoint to the upv framework
  * should exist in the root of every upv project
* `upv project`
  * usually corresponds to a Git repository
* `upv module`
  * a sub-directory inside an `upv project`
* `upv.yaml`
  * may be present in the root directory of an `upv module`
  * provides metadata / static configurations for the module
