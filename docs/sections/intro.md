
## Features

- **WFDB wrappers and helpers**. A small subset of the PhysioNet WFDB tools are
  wrapped with matlab functions, to allow using them directly from matlab. For
  example,
    * `mhrv.wfdb.gqrs` - A QRS detection algorithm.
    * `mhrv.wfdb.rdsamp` - For reading PhysioNet signal data into matlab.
    * `mhrv.wfdb.rdann` - For reading PhysioNet annotation data into matlab.
    * `mhrv.wfdb.wrann` - For writing PhysioNet annotation data from matlab datatypes.
    * `mhrv.wfdb.wfdb_header` - Read record metadata from a WFDB header file (`.hea`).

- **ECG signal processing**. Peak detection and RR interval extraction from ECG data
  in PhysioNet format. For example,
    * `mhrv.wfdb.rqrs` - Detection of R-peaks in ECG signals (based on PhysioNet's
      `gqrs`). Configurable for use with both human and animal ECGs.
    * `mhrv.ecg.jqrs`/`mhrv.ecg.wjqrs` - An ECG peak-detector based on a modified Pan & Tompkins
      algorithm and a windowed version.
    * `mhrv.ecg.bpfilt`- Bandpass filtering for removing noise artifacts from ECG
      signals.
    * `mhrv.wfdb.ecgrr` - Construction of RR intervals from ECG data in PhysioNet format.
    * `mhrv.wfdb.qrs_compare` - Comparison of QRS detections to reference annotations and
      calculation of quality measures like Sensitivity, PPV.

- **RR-intervals signal processing**. Ectopic beat rejection, frequency filtering,
  nonlinear dynamic and fractal analysis. For example,
    * `mhrv.rri.filtrr` - Filtering of RR interval time series to detect ectopic (out of
      place) beats.
    * `mhrv.rri.dfa` - Detrended Fluctuation Analysis, a method of estimating the fractal
      scaling exponent of a signal [3].
    * `mhrv.rri.mse` - Multiscale Sample Entropy, a measure of the complexity of the
      signal computed on multiple time scales [4].
    * `mhrv.rri.sample_entropy` - Sample Entropy, a measure of the irregularity of a signal.

* HRV Metrics: Calculating quantitative measures that indicate the activity of
    the heart based on RR intervals using all standard HRV metrics defined in
    the literature (see e.g. [2]).
    * `mhrv.hrv.hrv_time` - Time Domain: AVNN, SDNN, RMSSD, pNNx.
    * `mhrv.hrv.hrv_freq` - Frequency Domain:
        * Total and normalized power in (configurable) VLF, LF, HF and custom
          user-defined bands.
        * Spectral power estimation using Lomb, Auto Regressive, Welch and FFT methods.
        * Additional frequency-domain features: LF/HF ratio, LF and HF peak
          frequencies, power-law scaling exponent (beta).
    * `mhrv.hrv.hrv_nonlinear` - Nonlinear methods:
        * Short- and long-term scaling exponents (alpha1, alpha2) based on DFA.
        * Sample Entropy and Multiscale sample entropy (MSE).
        * Poincaré plot metrics (SD1, SD2).
    * `mhrv.hrv.hrv_fragmentation` - Time-domain RR interval fragmentation analysis [5].

* Configuration: The toolbox is fully configurable with many user-adjustable
  parameters.
    * The configuration files are in human-readable YAML format which
      is easy to edit and extend.
    * The user can create custom configurations files based on the
      `defatuls.yml` file (only overriding what's required).
    * Custom configuration files can be loaded with a single call which updates
      the defaults for the entire toolbox. This allows simple, reproducible
      analysis of different datasets that require different analysis
      configurations. See the `mhrv.defaults` package.
    * The settings for any of the functions can either be configured globally
      with configuration `yml` files or on a per-call basis with matlab-style
      key-value argument pairs.

* Plotting: All toolbox functions support plotting their output for data
  visualization. The plotting code is separated from the algorithmic code in
  order to simplify embedding this toolbox in other matlab applications.
  See the `mhrv.plots` package.

* Top-level analysis functions: These functions work with PhysioNet records and
  allow streamlined HRV analysis by composing the functions of this toolbox.
    * `mhrv.mhrv` - Analyzes a single PhysioNet record (ECG data or annotations),
      optionally split into multiple analysis windows.  Extracts all
      supported HRV features and optionally generates plots.
    * `mhrv.mhrv_batch` - Analyzes many PhysioNet records (ECG data or annotations) which
      can be further separated into user-defined groups (e.g. Control, Test).
      Automatically computes HRV metrics per group and generates a comparative
      summary of the HRV features in each group.
