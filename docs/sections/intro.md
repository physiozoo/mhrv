`mhrv` is a matlab toolbox for calculating Heart-Rate Variability (HRV) metrics
from both ECG signals and RR-interval time series. The toolbox works with ECG
data in the [PhysioNet](https://physionet.org/) WFDB data format.

## Features

- **WFDB wrappers and helpers**. A small subset of the PhysioNet WFDB tools are
  wrapped with matlab functions, to allow using them directly from matlab.

- **ECG signal processing**. Peak detection and RR interval extraction from ECG data
  in PhysioNet format.

- **RR-intervals signal processing**. Ectopic beat rejection, frequency filtering,
  nonlinear dynamic and fractal analysis.

- **HRV Metrics**. Calculating quantitative measures that indicate the activity of
  the heart based on RR intervals using all standard HRV metrics defined in the
  literature.

- **Configuration**. The toolbox is fully configurable with many user-adjustable
  parameters. Everything can be configured either globally with human readable
  YAML config files, or when calling the toolbox functions via matlab style
  key-value pair arguments.

- **Plotting**. All toolbox functions support plotting their output for data
  visualization. The plotting code is separated from the algorithmic code in
  order to simplify embedding this toolbox in other matlab applications.

- **Top-level analysis functions**. These functions work with PhysioNet records and
  allow streamlined HRV analysis by composing the functions of this toolbox.
  Supports multi-record batch analysis for calculating HRV features of large
  datasets.
