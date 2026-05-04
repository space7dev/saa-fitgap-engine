# SAAccelerate Fit-Gap Engine

This repository contains the solution for **Task 2 – Fit-gap engine / logic in ABAP**.

The implementation is a pure ABAP Cloud class that compares a customer's actual configuration against a baseline configuration and returns a deterministic list of fit-gap results.

## Main Object

`ZCL_SAA_FITGAP_ENGINE`

## Package

`ZSAA_FITGAP`

## Runtime

- SAP BTP ABAP Environment Trial
- Eclipse ADT
- ABAP Cloud
- ABAP Unit

## Repository Structure

```text
saa-fitgap-engine/
  .abapgit.xml
  README.md
  DECISIONS.md
  src/
    zcl_saa_fitgap_engine.clas.abap
    zcl_saa_fitgap_engine.clas.xml
  screenshots/
    green.png
    coverage.png