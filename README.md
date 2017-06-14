# rhrv

Matlab tools for calculating Heart-Rate Variability (HRV) metrics on ECG
signals. Supports working with the [PhysioNet](https://physionet.org/) data
format.

## Features

* WFDB wrappers: A small subset of the WFDB tools are wrapped with matlab functions.
    * `gqrs` - A QRS detection algorithm.
    * `rdsamp` - For reading PhysioNet signal data into matlab.
    * `rdann` - For reading PhysioNet annotation data into matlab.

* QRS detection: Finding the beats in ECG signals.
    * `rqrs` - Detection of R-peaks in ECG signals (based on PhysioNet's `gqrs`). Configurable for use with both human and animal ECGs.
    * `qrs_compare` - Comparison of QRS detections to reference annotations and calculation of quality indices like Sensitivity, PPV.

* ECG signal processing
     * `egcrr` - Construction of RR intervals from ECG data in PhysioNet format.
     * `filtrr` - Filtering of RR interval time series to detect ectopic (out of place) beats.

* HRV Metrics: Calculating quantative measures that indicate the activity of the heart based on RR intervals.
    * `hrv_time` - Time Domain: AVNN, SDNN, pXNN.
    * `hrv_freq` - Frequency Domain:
        * Total and normalized power in VLF, LF and HF bands.
        * Spectral power estimation using Lomb, Auto Regressive, Welch and FFT methods.
    * `hrv_nonlinear` - Nonlinear methods:
        * Detrended fluctuation analysis (DFA), with short- and long-term scaling exponents (alpha1, alpha2).
        * Spectral power-law scaling exponent (beta).
        * Multiscale sample entropy (MSE).
        * Poincaré plot metrics (SD1, SD2).
    * `hrv_fragmentation` - Time-domain RR interval fragmentation analysis.

## Requirements
* Matlab with Signal Processing toolbox. Should work on Matlab R2014b or newer.
* The Pysionet WFDB tools. The toolbox can install this for you.

## Installation

1. Clone the repo or download the source code.

2. From MATLAB, run the `rhrv_init` function. This function will:

    * Check for the presence of the WFDB tools in your system `PATH`. If WFDB
      tools are not detected, it will attempt to automatically download them for
      you into the folder `bin/wfdb` under the repository root.
    * Set up your MATLAB path to include the code from this toolbox.

### Manual WFDB Installation (Optional)
The above steps should be enough to get most users started. If however you
don't want `rhrv_init` to download the WFDB tools for you, or the automatic
installation fails for some reason, you can install them yourself.

  * On OSX, you can use [homebrew](http://brew.sh) to install it easily with `brew install homebrew/science/wfdb`.
  * On Windows and Linux, you should either [download the WFDB binaries](https://physionet.org/physiotools/binaries/)
    for your OS or compile them [from source](https://physionet.org/physiotools/wfdb.shtml#downloading)
    using the instructions on their website.

Once you have the binaries, place them in some folder on your `$PATH` or somewere under the repo's
root folder (`bin/wfdb` would be a good choice as it's `.gitignore`d) and they will be found and
used automatically. Or, if you would like to manually specify a path outside the repo which contains
the WFDB binaries (e.g. `/usr/local/bin` for a homebrew install), you can edit
[`cfg/defaults.yml`](https://github.com/avivrosenberg/rhrv/blob/master/cfg/defaults.yml) and set
the `rhrv.paths.wfdb_path` variable to the desired path.

For linux users it's recommended to install from source as the binaries
provided on the PhysioNet website are very outdated.

## Usage
Exaple of calculating HRV measures for a PhysioNet record (in this case from [`mitdb`](https://www.physionet.org/physiobank/database/mitdb/)):
```
>> rhrv('db/mitdb/111', 'window_minutes', 15, 'plot', true);
```
Will give you:
```
[0.000] >> rhrv: Processing ECG signal from record db/mitdb/111 (ch. 1)...
[0.000] >> rhrv: Signal duration: 00:30:05.000 [HH:mm:ss.ms]
[0.010] >> rhrv: Analyzing window 1 of 2...
[0.010] >> rhrv: [1/2] Detecting QRS end RR intervals...
[0.810] >> rhrv: [1/2] Filtering RR intervals...
[0.840] >> rhrv: [1/2] 1039 NN intervals, 6 RR intervals were filtered out
[0.840] >> rhrv: [1/2] Calculating time-domain metrics...
[0.920] >> rhrv: [1/2] Calculating frequency-domain metrics...
[1.180] >> rhrv: [1/2] Calculating nonlinear metrics...
[1.430] >> rhrv: [1/2] Calculating fragmentation metrics...
[1.490] >> rhrv: Analyzing window 2 of 2...
[1.490] >> rhrv: [2/2] Detecting QRS end RR intervals...
[2.080] >> rhrv: [2/2] Filtering RR intervals...
[2.100] >> rhrv: [2/2] 1057 NN intervals, 8 RR intervals were filtered out
[2.100] >> rhrv: [2/2] Calculating time-domain metrics...
[2.140] >> rhrv: [2/2] Calculating frequency-domain metrics...
[2.240] >> rhrv: [2/2] Calculating nonlinear metrics...
[2.450] >> rhrv: [2/2] Calculating fragmentation metrics...
[2.490] >> rhrv: Building statistics table...
[2.520] >> rhrv: Displaying Results...
               RR      NN      AVNN      SDNN     RMSSD      pNN50       SEM      TOTAL_POWER_LOMB    VLF_POWER_LOMB    LF_POWER_LOMB    HF_POWER_LOMB    LF_NORM_LOMB    HF_NORM_LOMB    LF_TO_HF_LOMB    LF_PEAK_LOMB    HF_PEAK_LOMB      SD1       SD2       alpha1      alpha2      beta      SampEn       PIP        IALS        PSS       PAS  
              ____    ____    ______    ______    ______    _______    _______    ________________    ______________    _____________    _____________    ____________    ____________    _____________    ____________    ____________    _______    ______    ________    ________    _______    _______    _______    _________    ______    ______
    1         1045    1039    858.96    30.961    33.622     14.162    0.96054    333.22              67.098            23.574           242.55           8.8583          91.142          0.097193          0.046667       0.16667          23.786    36.745     0.65937     0.72845    -1.2471      1.835     53.321      0.53468    61.598    12.512
    2         1065    1057    841.86    40.182    32.306     12.784     1.2359    388.66               132.7            32.031           223.93           12.514          87.486           0.14304          0.043333       0.16667          22.855    51.996     0.70064     0.92309    -1.6706     1.6483     52.318      0.52462    57.332    15.137
    Mean      1055    1048    850.41    35.572    32.964     13.473     1.0982    360.94              99.899            27.802           233.24           10.686          89.314           0.12012             0.045       0.16667           23.32    44.371        0.68     0.82577    -1.4588     1.7417     52.819      0.52965    59.465    13.825
    SE          10       9    8.5503    4.6103    0.6578    0.68888     0.1377    27.723              32.801            4.2286           9.3065           1.8278          1.8278          0.022923         0.0016667             0         0.46545    7.6255    0.020637    0.097316    0.21176    0.09336    0.50131    0.0050304    2.1328    1.3126
    Median    1055    1048    850.41    35.572    32.964     13.473     1.0982    360.94              99.899            27.802           233.24           10.686          89.314           0.12012             0.045       0.16667           23.32    44.371        0.68     0.82577    -1.4588     1.7417     52.819      0.52965    59.465    13.825
[2.580] >> rhrv: Generating plots...
[4.930] >> rhrv: Finished processing record db/mitdb/111.

```
The `window_minutes` parameter allow splitting the signal into windows and
calculating all metrics per window. You can pass in an empty array `[]` to
disable spliting.

Note that in order to run the example you need to first download the relevant
record (`mitdb/111`) from PhysioNet's [`mitdb` database](https://physionet.org/physiobank/database/mitdb/)
(both `.dat` and `.hea` files). In the example, they were downloaded to the
folder `db/mitdb` relative to MATLABs current folder. Any relative or absolute
path can be used.  See also [this FAQ](https://physionet.org/faq.shtml#downloading-databases)
in case you would like to download entire PhysioNet databases in bulk. 

Example plots (generated by the example above):

* ECG R-peak detection ![Example Peak Detection](https://github.com/avivrosenberg/rhrv/blob/master/fig/example_ecg.png?raw=true)
* RR interval time series filtering ![Example RR filtering](https://github.com/avivrosenberg/rhrv/blob/master/fig/example_nn.png?raw=true)
* Time-domain HRV Metrics ![Example time domain metrics](https://github.com/avivrosenberg/rhrv/blob/master/fig/example_time.png?raw=true)
* Spectrum of interval time series ![Example NN spectrum](https://github.com/avivrosenberg/rhrv/blob/master/fig/example_spectrum.png?raw=true)
* Nonlinear HRV Metrics ![Example nonlinear metrics](https://github.com/avivrosenberg/rhrv/blob/master/fig/example_hrv.png?raw=true)
* Poincaré plot and ellipse fitting ![Example poincaré plot](https://github.com/avivrosenberg/rhrv/blob/master/fig/example_poincare.png?raw=true)

## Attribution
This project is in a early iteration and is intended for my research as part of
my MSc thesis and other unpublished papers.  Information about how to cite this
work will be added in the near future.

Some of the code in `lib/` was created by others, used here as dependencies.
Original author attribution exists in the source files.

## Contributing
Feel free to send pull requests or open issues.

