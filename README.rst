.. -*- mode: rst -*-

swa-matlab
==========

This toolbox is designed for the waveform analysis of EEG data acquired during sleep; primarily high density recordings of substantial duration (e.g. >64 channels, >5min of continuous recording). Slow waves, spindles, and saw-tooth waves are able to be automatically detected using sophisticated algorithms using minimal assumptions and parameters settings. Distinct output parameters (e.g. slow-wave amplitude), are provided for each wave found which can then be further explored. Moreover, travelling parameters for each wave are also detected.

The toolbox further provides a GUI interface from which you can freely explore the results of the analysis by examining the properties of each wave found, manually adding or subtracting individual channels from the waveform or rejecting a wave altogether. The results are displayed as time-series or topographical maps which can be easily edited and exported into stand-alone figures.

The toolbox also implements a basic sleep scoring GUI which allows the user to manually set the sleep stage in user defined lengths (e.g. 30 second epochs) and export individual stages to a file format ready to analyse using the swa toolbox.

Get the latest code
^^^^^^^^^^^^^^^^^^^

To get the lastest code using git, simply type::

  git clone git://github.com/Mensen/swa-matlab.git

Installation
^^^^^^^^^^^^

After you've downloaded the toolbox, add the path to matlab using ``setpath`` and take a look at some of the processing template files to get started.

Dependencies
^^^^^^^^^^^^

All the main dependencies for the toolbox are provided in the *dependencies* folder. The primary external dependency for using the GUI is the tools provided by `undocumented matlab toolbox <http://undocumentedmatlab.com>`_ which adds essential features to the typical GUI in matlab.

In order to use some of the additional features of the toolbox, as well as taking advantage of the specific formatting required to use the sleep scoring section we recommend installing the latest version of `EEGLAB <http://sccn.ucsd.edu/eeglab/downloadtoolbox.html>`_

Getting Started
^^^^^^^^^^^^^^^

Run the swa_SleepScoring function to score the stages of your raw EEG file. Then use the swa_preprocessingTemplate script to see some suggestions on how to preprocess your raw EEG data to get it ready for wave detection.

Or: use the already preprocessed example dataset in the Templates folder.

See one of the template files in the wave type directory (e.g. SW/swa_SW_Template.m) to get an idea of the necessary steps for wave detection and analysis.

Use the swa_Explorer to visualise the results of the wave detection and manually add or remove waves found in the analysis.

Troubleshooting
^^^^^^^^^^^^^^^

Since the swa-matlab toolbox is under constant development, there are bound to be a considerable number of bugs or feature requests over time. Please use the GitHub *issues* forum for any questions or comments you might have regarding the toolbox.

