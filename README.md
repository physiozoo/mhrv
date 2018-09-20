# mhrv

`mhrv` is a matlab toolbox for calculating Heart-Rate Variability (HRV) metrics
from both ECG signals and RR-interval time series. The toolbox works with ECG
data in the [PhysioNet](https://physionet.org/) [1] WFDB data format.

## Features

- **WFDB wrappers and helpers**. A small subset of the PhysioNet WFDB tools are
  wrapped with matlab functions, to allow using them directly from matlab.
    * `gqrs` - A QRS detection algorithm.
    * `rdsamp` - For reading PhysioNet signal data into matlab.
    * `rdann` - For reading PhysioNet annotation data into matlab.
    * `wrann` - For writing PhysioNet annotation data from matlab datatypes.
    * `wfdb_header` - Read record metadata from a WFDB header file (`.hea`).

- **ECG signal processing**. Peak detection and RR interval extraction from ECG data
  in PhysioNet format.
    * `rqrs` - Detection of R-peaks in ECG signals (based on PhysioNet's
      `gqrs`). Configurable for use with both human and animal ECGs.
    * `jqrs`/`wjqrs` - An ECG peak-detector based on a modified Pan & Tompkins
      algorithm and a windowed version.
    * `bpfilt`- Bandpass filtering for removing noise artifacts from ECG
      signals.
    * `ecgrr` - Construction of RR intervals from ECG data in PhysioNet format.
    * `qrs_compare` - Comparison of QRS detections to reference annotations and
      calculation of quality measures like Sensitivity, PPV.

- **RR-intervals signal processing**. Ectopic beat rejection, frequency filtering,
  nonlinear dynamic and fractal analysis.
    * `filtrr` - Filtering of RR interval time series to detect ectopic (out of
      place) beats.
    * `dfa` - Detrended Fluctuation Analysis, a method of estimating the fractal
      scaling exponent of a signal [3].
    * `mse` - Multiscale Sample Entropy, a measure of the complexity of the
      signal computed on multiple time scales [4].
    * `sample_entropy` - Sample Entropy, a measure of the irregularity of a signal.

* HRV Metrics: Calculating quantitative measures that indicate the activity of
    the heart based on RR intervals using all standard HRV metrics defined in
    the literature (see e.g. [2]).
    * `hrv_time` - Time Domain: AVNN, SDNN, RMSSD, pNNx.
    * `hrv_freq` - Frequency Domain:
        * Total and normalized power in (configurable) VLF, LF, HF and custom
          user-defined bands.
        * Spectral power estimation using Lomb, Auto Regressive, Welch and FFT methods.
        * Additional frequency-domain features: LF/HF ratio, LF and HF peak
          frequencies, power-law scaling exponent (beta).
    * `hrv_nonlinear` - Nonlinear methods:
        * Short- and long-term scaling exponents (alpha1, alpha2) based on DFA.
        * Sample Entropy and Multiscale sample entropy (MSE).
        * Poincaré plot metrics (SD1, SD2).
    * `hrv_fragmentation` - Time-domain RR interval fragmentation analysis [5].

* Configuration: The toolbox is fully configurable with many user-adjustable
  parameters.
    * The configuration files are in human-readable YAML format which
      is easy to edit and extend.
    * The user can create custom configurations files based on the
      `defatuls.yml` file (only overriding what's required).
    * Custom configuration files can be loaded with a single call which updates
      the defaults for the entire toolbox. This allows simple, reproducible
      analysis of different datasets that require different analysis
      configurations.
    * The settings for any of the functions can either be configured globally
      with configuration `yml` files or on a per-call basis with matlab-style
      key-value argument pairs.

* Plotting: All toolbox functions support plotting their output for data
  visualization. The plotting code is separated from the algorithmic code in
  order to simplify embedding this toolbox in other matlab applications.

* Top-level analysis functions: These functions work with PhysioNet records and
  allow streamlined HRV analysis by composing the functions of this toolbox.
    * `mhrv` - Analyzes a single PhysioNet record (ECG data or annotations),
      optionally split into multiple analysis windows.  Extracts all
      supported HRV features and optionally generates plots.
    * `mhrv_batch` - Analyzes many PhysioNet records (ECG data or annotations) which
      can be further separated into user-defined groups (e.g. Control, Test).
      Automatically computes HRV metrics per group and generates a comparative
      summary of the HRV features in each group.

## Requirements

* Matlab with Signal Processing toolbox. Should work on Matlab R2014b or newer.
* The [PhysioNet WFDB tools](https://www.physionet.org/physiotools/wfdb.shtml).
  The toolbox can install this for you.

## Installation

1. Clone the repo or download the source code.

2. From MATLAB, run the `mhrv_init` function. This function will:

    * Check for the presence of the WFDB tools in your system `PATH`. If WFDB
      tools are not detected, it will attempt to automatically download them for
      you into the folder `bin/wfdb` under the repository root.
    * Set up your MATLAB path to include the code from this toolbox.

### Manual WFDB Installation (Optional)

The above steps should be enough to get most users started. If however you
don't want `mhrv_init` to download the WFDB tools for you, or the automatic
installation fails for some reason, you can install them yourself.

  * On OSX, you can use [homebrew](http://brew.sh) to install it easily with
      `brew install wfdb`.
  * On Windows and Linux, you should either [download the WFDB
      binaries](https://physionet.org/physiotools/binaries/)
      for your OS or compile them [from
      source](https://physionet.org/physiotools/wfdb.shtml#downloading)
      using the instructions on their website.

Once you have the binaries, place them in some folder on your `$PATH` or
somewere under the repo's root folder (`bin/wfdb` would be a good choice as it's
`.gitignore`d) and they will be found and used automatically. Or, if you would
like to manually specify a path outside the repo which contains the WFDB
binaries (e.g. `/usr/local/bin` for a homebrew install), you can edit
[`cfg/defaults.yml`](https://github.com/avivrosenberg/mhrv/blob/master/cfg/defaults.yml)
and set the `mhrv.paths.wfdb_path` variable to the desired path.

For linux users it's recommended to install from source as the binaries provided
on the PhysioNet website are very outdated.

## Documentation

Documentation is available on
[readthedocs](https://mhrv.readthedocs.io/en/latest/).

## Usage
Exaple of calculating HRV measures for a PhysioNet record downloaded from
PhysioNet (in this case from
[`mitdb`](https://www.physionet.org/physiobank/database/mitdb/)):

```matlab
% Download the mitdb/111 record from PhysioNet to local folder named 'db'
>> download_wfdb_records('mitdb', '111', 'db');

% Run HRV analysis
>> mhrv('db/mitdb/111', 'window_minutes', 15, 'plot', true);
```

Will give you:
```
[0.000] >> mhrv: Processing ECG signal from record db/mitdb/111 (ch. 1)...
[0.000] >> mhrv: Signal duration: 00:30:05.000 [HH:mm:ss.ms]
[0.010] >> mhrv: Analyzing window 1 of 2...
[0.010] >> mhrv: [1/2] Detecting QRS end RR intervals...
[0.810] >> mhrv: [1/2] Filtering RR intervals...
[0.840] >> mhrv: [1/2] 1039 NN intervals, 6 RR intervals were filtered out
[0.840] >> mhrv: [1/2] Calculating time-domain metrics...
[0.920] >> mhrv: [1/2] Calculating frequency-domain metrics...
[1.180] >> mhrv: [1/2] Calculating nonlinear metrics...
[1.430] >> mhrv: [1/2] Calculating fragmentation metrics...
[1.490] >> mhrv: Analyzing window 2 of 2...
[1.490] >> mhrv: [2/2] Detecting QRS end RR intervals...
[2.080] >> mhrv: [2/2] Filtering RR intervals...
[2.100] >> mhrv: [2/2] 1057 NN intervals, 8 RR intervals were filtered out
[2.100] >> mhrv: [2/2] Calculating time-domain metrics...
[2.140] >> mhrv: [2/2] Calculating frequency-domain metrics...
[2.240] >> mhrv: [2/2] Calculating nonlinear metrics...
[2.450] >> mhrv: [2/2] Calculating fragmentation metrics...
[2.490] >> mhrv: Building statistics table...
[2.520] >> mhrv: Displaying Results...
               RR      NN      AVNN      SDNN     RMSSD      pNN50       SEM      TOTAL_POWER_LOMB    VLF_POWER_LOMB    LF_POWER_LOMB    HF_POWER_LOMB    LF_NORM_LOMB    HF_NORM_LOMB    LF_TO_HF_LOMB    LF_PEAK_LOMB    HF_PEAK_LOMB      SD1       SD2       alpha1      alpha2      beta      SampEn       PIP        IALS        PSS       PAS  
              ____    ____    ______    ______    ______    _______    _______    ________________    ______________    _____________    _____________    ____________    ____________    _____________    ____________    ____________    _______    ______    ________    ________    _______    _______    _______    _________    ______    ______
    1         1045    1039    858.96    30.961    33.622     14.162    0.96054    333.22              67.098            23.574           242.55           8.8583          91.142          0.097193          0.046667       0.16667          23.786    36.745     0.65937     0.72845    -1.2471      1.835     53.321      0.53468    61.598    12.512
    2         1065    1057    841.86    40.182    32.306     12.784     1.2359    388.66               132.7            32.031           223.93           12.514          87.486           0.14304          0.043333       0.16667          22.855    51.996     0.70064     0.92309    -1.6706     1.6483     52.318      0.52462    57.332    15.137
    Mean      1055    1048    850.41    35.572    32.964     13.473     1.0982    360.94              99.899            27.802           233.24           10.686          89.314           0.12012             0.045       0.16667           23.32    44.371        0.68     0.82577    -1.4588     1.7417     52.819      0.52965    59.465    13.825
    SE          10       9    8.5503    4.6103    0.6578    0.68888     0.1377    27.723              32.801            4.2286           9.3065           1.8278          1.8278          0.022923         0.0016667             0         0.46545    7.6255    0.020637    0.097316    0.21176    0.09336    0.50131    0.0050304    2.1328    1.3126
    Median    1055    1048    850.41    35.572    32.964     13.473     1.0982    360.94              99.899            27.802           233.24           10.686          89.314           0.12012             0.045       0.16667           23.32    44.371        0.68     0.82577    -1.4588     1.7417     52.819      0.52965    59.465    13.825
[2.580] >> mhrv: Generating plots...
[4.930] >> mhrv: Finished processing record db/mitdb/111.

```

The `window_minutes` parameter allow splitting the signal into windows and
calculating all metrics per window. You can pass in an empty array `[]` to
disable spliting.

Example plots (generated by the example above):

* ECG R-peak detection ![Example Peak Detection](https://github.com/avivrosenberg/mhrv/blob/master/fig/example_ecg.png?raw=true)
* RR interval time series filtering ![Example RR filtering](https://github.com/avivrosenberg/mhrv/blob/master/fig/example_nn.png?raw=true)
* Time-domain HRV Metrics ![Example time domain metrics](https://github.com/avivrosenberg/mhrv/blob/master/fig/example_time.png?raw=true)
* Spectrum of interval time series ![Example NN spectrum](https://github.com/avivrosenberg/mhrv/blob/master/fig/example_spectrum.png?raw=true)
* Nonlinear HRV Metrics ![Example nonlinear metrics](https://github.com/avivrosenberg/mhrv/blob/master/fig/example_hrv.png?raw=true)
* Poincaré plot and ellipse fitting ![Example poincaré plot](https://github.com/avivrosenberg/mhrv/blob/master/fig/example_poincare.png?raw=true)


## Citing

This toolbox, initially called `rhrv`, was created as part of my MSc research
thesis. It was then renamed and updated to be used  as the basis of the
[PhysioZoo](https://physiozoo.github.io) platform for HRV analysis of human and
animal data.

To use it in you own research, please cite:

* Rosenberg, A. A. (2018) ‘Non-invasive in-vivo analysis of intrinsic clock-like
  pacemaker mechanisms: Decoupling neural input using heart rate variability
  measurements.’ MSc Thesis. Technion, Israel Institute of Technology.

* Behar J. A., Rosenberg A. A. et. al. (2018) ‘PhysioZoo: a novel open access
  platform for heart rate variability analysis of mammalian
  electrocardiographic data.’ Frontiers in Physiology.


## Similar projects

Several other projects exist with various levels of overlapping functionality and
purpose.

* The [PhysioNet WFDB tools](https://www.physionet.org/physiotools/wfdb.shtml).
* The [WFDB toolbox for
  matlab](https://www.physionet.org/physiotools/matlab/wfdb-app-matlab/).
* The [R-HRV](http://rhrv.r-forge.r-project.org/) toolbox for the R language.
* The [Kubios](https://www.kubios.com/) software package.
* The [PhysioZoo](https://physiozoo.github.io/) platform for mammalian ECG and
  HRV analysis.

## Attribution

Some of the code in `lib/` was created by others, used here as dependencies.
Original author attribution exists in the source files.

## Contribution

Feel free to send pull requests or open issues via GitHub.

## References

1. Goldberger, A. L. et al. (2000) ‘PhysioBank, PhysioToolkit, and PhysioNet’,
   Circulation, 101(23), pp. E215-20.
2. Task Force of the European Society of Cardiology and the North American
   Society of Pacing and Electrophysiology. (1996) ‘Heart rate variability.
   Standards of measurement, physiological interpretation, and clinical use.’,
   European Heart Journal, 17(3), pp. 354–81.
3. Peng, C.-K., Hausdorff, J. M. and Goldberger, A. L. (2000) ‘Fractal mechanisms
   in neuronal control: human heartbeat and gait dynamics in health and disease,
   Self-organized biological dynamics and nonlinear control.’ Cambridge:
   Cambridge University Press.
4. Costa, M. D., Goldberger, A. L. and Peng, C.-K. (2005) ‘Multiscale entropy
   analysis of biological signals’, Physical Review E - Statistical, Nonlinear,
   and Soft Matter Physics, 71(2), pp. 1–18.
5. Costa, M. D., Davis, R. B. and Goldberger, A. L. (2017) ‘Heart Rate
   Fragmentation : A New Approach to the Analysis of Cardiac Interbeat Interval
   Dynamics’, Frontiers in Physiology, 8(May), pp. 1–13.

