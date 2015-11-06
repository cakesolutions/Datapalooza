# Muvr

[muvr](http://www.muvr.io/) is a demonstration of an application that uses _wearable devices_ (Pebble)—in combination with a mobile app—to submit physical (i.e. accelerometer, compass) and biological (i.e. heart rate) information to a CQRS/ES cluster to be analysed.

#### muvr-ios
`muvr-ios` is a fitness app showcasing the possibilities of mobile analytics. The app collects data from sensors (e.g. a pebble watch) and uses the information to classify your movements to keep track of your workout.

This part of the project is mostly written using Swift 2. Some classes use Objective-C / Objective-C++ for easier interfacing with external libraries.

#### Other components of the system
- [muvr-server](https://github.com/muvr/muvr-server) CQRS/ES cluster 
- [muvr-pebble](https://github.com/muvr/muvr-pebble) Pebble application, example implementation of a wearable device 
- [muvr-preclassification](https://github.com/muvr/muvr-preclassification) mobile data processing and classification
- [muvr-analytics](https://github.com/muvr/muvr-analytics) machine learning model generation for movement analytics

## Getting started
Basic information to get started is below. Please also have a look at the other components of the system to get a better understanding how everything fits together.

### Installation
Make sure your Xcode is up to date (>= 7.0) and you got [cocoapots](https://cocoapods.org/) installed .
```
git clone git@github.com:muvr/muvr-ios.git

# To compile the ios app you will also need the preclassification project
git clone git@github.com:muvr/muvr-preclassification.git

cd muvr-ios
pod install
```
Build and run the project using Xcode.

### Issues

For any bugs or feature requests please:

1. Search the open and closed
   [issues list](https://github.com/muvr/muvr-ios/issues) to see if we're
   already working on what you have uncovered.
2. Make sure the issue / feature gets filed in the relevant components (e.g. server, analytics, ios)
3. File a new [issue](https://github.com/muvr/muvr-ios/issues) or contribute a 
  [pull request](https://github.com/muvr/muvr-ios/pulls) 

## License
Please have a look at the [LICENSE](https://github.com/muvr/muvr-ios/blob/develop/LICENSE) file.

