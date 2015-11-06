# muvr-training-data

This repository is a collection of training datasets used for analysis and model training during model evaluation. 
Newly added datasets should be listed here including there format and a short description.

Some of the datasets might be zipped since they would be to big otherwise.

## (partial) List of available datasets

The default format is **single-exercise-extended**. 

#### combined

| name                                         	| format                 	| zipped 	| split    	| comment                                                                	|
|----------------------------------------------	|------------------------	|:------:	|----------	|------------------------------------------------------------------------	|
| 18-09-15-triceps-biceps-lateral.zip 	| single-exercise-extended 	|    x   	|          	| Collection of three exercises.                                         	|
| combined-tbl-activity-slacking-(test/train).zip  	| single-exercise-extended 	|    x   	| presplit 	| Combination of activity data and triceps-biceps-lateral |

#### labelled
Jan's collected exercises. Contains `single-exercise-extended` data files.

## Format descriptions

#### single-exercise-extended
The dataset is a collection of **labeled** data, one file per exercise. A file for an exercise is in CSV format and there is one row per measurement:
```
x | y | z | exercise name | intensity | weight | repetitions |
```

#### single-exercise-simple (deprecated)
The dataset is a collection of **labeled** data, one file per exercise. A file for an exercise is in CSV format and there is one row per measurement:
```
exercise group | exercise name | x | y | z |
```

#### combined-1200 (deprecated)
The dataset is a collection of **labeled** data in a single file. The file is in CSV and there is one row per example:
```
label | X1 | X2 | ... | X400  | Y1 | Y2 | ... | Y400   | Z1 | Z2 | ... | Z400 
```
