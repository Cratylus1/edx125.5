---
title: |
  | \vspace{0.5cm} \Large Capstone Project HarvardX PH125.9x:Report
  | \vspace{.05cm} \Large July 23, 2021
output:
  pdf_document:
    toc: yes
    toc_depth: '3'
    fig_caption: yes
    number_sections: yes
  citation_package: apacite
bibliography: c:/users/support/desktop/sandbox/r_projects/movielens_edx/capstone_references.bib
---
```{r setup, include=FALSE}
inline_hook <- function(x){
    if(is.numeric(x)) {
        if(abs(x-round(x)) < .Machine$double.eps) {
            x <- format(x,digits=4, big.mark=",")
        } else {
            x <- format(x,digits=4, nsmall=2, big.mark=",")
        }
    } else {
        x <-x
    }
    x
}

knitr::knit_hooks$set(inline = inline_hook) 
knitr::opts_chunk$set(echo = TRUE)
```

\pagebreak
\begin{center}
\LARGE HarvardX PH125.9x: Capstone Project: MovieLens Modeling
\end{center}
\vspace{2cm}

# Introduction
The objective of this capstone project is to develop/identify a machine learning (ML) model that will predict movie ratings based on the data contained in the MovieLens database. \par

The MovieLens database utilized for this capstone project contains 10 Million ratings of 10,000 movies by 72,000 users [@movie01].  For the history and context of the MovieLens database see @timestamp01.  Movies are classified by genre, e.g. *Romance*, or by multiple genre, e.g. *Adventure/Romance/Science Fiction.*  Data is captured for each review of a movie with each entry (observation) containing the movie name, reviewers Id and the discrete numerical ratings assigned by the reviewers which quantify their 'recommendation' for each movie. Additional data, such as movie year of release and the date/time of the review, are also captured. \par

In general, the MovieLens database will be divided into two subsets: edx and validation.  The edx subset will then be further divided into training and testing subsets. After an exploratory data analysis (EDA) of the training subset is performed, ML models will be developed on that subset to predict ratings of movies. Various ML techniques covered in the edX coursework will be examined.  These various models will then be tested on the test subset so that their ability to correctly predict the recommendation can be quantified using the the root mean squared error (RMSE) metric.  The models will be iteratively developed and fine-tuned during this process.  A final-model will then be selected based on RMSE results.  Finally, we will hold our breath and run the final-model on the validation/final-testing subset, calculate the RMSE and submit the results in this paper!  Re-runs/fine-tuning on the validaton/final-testing subset is not allowed so as to simulate a real-world situation.  This project report concludes with some thoughts and recommendations on model(s) performance. \par

The report is organized as follows: 
\begin{itemize}
 \item \emph{Methods and Analysis} - This section of the report discusses the exploratory data analysis of the training subset, develops, presents and evaluates various models developed utilizing the test subset and reports the RMSE accuracy of each model.  Based on this analysis a final model is chosen for use.
 \item \emph{Results} - This section discusses the performance of the final model in predicting the reviewer recommendations in the validation/final-testing subset.  This model will be run only once utilizing the validation/final-testing subset and the performance metric will be reported.
 \item \emph{Conclusion} This final section provides a summary discussing this work and its limitations with the suggestion for possible future work.
 \end{itemize}

All programming is conducted in @R-base with various additional library packages such as *caret*.  This document was created in RMarkdown [@r-mkd] and this is my first paper that utilizes it -- so I learned a lot, and still hae a lot to learn!\par

# Methods and Analysis
Within this section, the *Load Data* subsection briefly discusses the creation of the three MovieLens subsets.  Then *Exploratory Data Analysis (EDA)* subsection loads the training and testing subsets and analyzes the training subset to gain insights that might help determine the best ML modeling approach.  Various candidate models are then presented and discussed in the *Models* section.  The candidate models will be tuned and tested on the testing subset with performance data calculated and tabulated in an iterative process.  Based on this process, a final model will be chosen in the *Final Model* subsection. \par 

## Load Data

This MovieLens database was first divided into two sets: *edx* and *validation* based on directions from and programming code supplied by Professor Rafael A. Irizarry [@directions01] which is presented here for completeness, but not discussed. The edx subset is then partitioned randomly on an 80%/20% basis into the *train/training* and the *test/testing* subsets. These two subsets will be utilized to develop, compare the performance of various models run with the testing data, and to chose a final-model. The *validation* subset is held-out for one-time (and only one-time!) use to assess the performance of the chosen final-model.

```{r read_data, echo=FALSE, eval=TRUE, message=FALSE}
#Read and Format Data Per Directions
##########################################################
# Create edx set, validation set (final hold-out test set)
##########################################################

# Note: this process could take a couple of minutes
defaultW <- getOption("warn") 
options(warn = -1) 
if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(data.table)) install.packages("data.table", repos = "http://cran.us.r-project.org")
if(!require(vctrs)) install.packages("vctrs", repos = "http://cran.us.r-project.org")
#if(!require(ellipsis)) install.packages("ellipsis", repos = "http://cran.us.r-project.org")
library(tidyverse)
library(caret)
library(data.table)
library(dplyr)
library(stringr)
library(ggrepel)
library(kfigr)
library(ggpubr)
library(dplyr)
library(ggplot2)
library(stringr)
library(knitr)
#speed up the process by only reading-in the data once, and just loading it from a saved
#file for subsequent executions see;https://rstudio-education.github.io/hopr/dataio.html
#
if(file.exists("capstone_data.RData")){
  load("capstone_data.RData")} else {
    
# MovieLens 10M dataset:
# https://grouplens.org/datasets/movielens/10m/
# http://files.grouplens.org/datasets/movielens/ml-10m.zip
#
options(warn = defaultW)
dl <- tempfile()

download.file("http://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)
#62.5MB
ratings <- fread(text = gsub("::", "\t", readLines(unzip(dl, "ml-10M100K/ratings.dat"))),
                 col.names = c("userId", "movieId", "rating", "timestamp"))

movies <- str_split_fixed(readLines(unzip(dl, "ml-10M100K/movies.dat")), "\\::", 3)
colnames(movies) <- c("movieId", "title", "genres")

# if using R 3.6 or earlier:
#movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(levels(movieId))[movieId],
#                                           title = as.character(title),
#                                           genres = as.character(genres))
# if using R 4.0 or later:
movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(movieId),
                                           title = as.character(title),
                                           genres = as.character(genres))
#

movielens <- left_join(ratings, movies, by = "movieId")
head(movielens)
# Validation set will be 10% of MovieLens data
set.seed(1, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]

# Make sure userId and movieId in validation set are also in edx set
validation <- temp %>% 
    semi_join(edx, by = "movieId") %>%
    semi_join(edx, by = "userId")

# Add rows removed from validation set back into edx set
removed <- anti_join(temp, validation)
edx <- rbind(edx, removed)

rm(dl, ratings, movies, test_index, temp, movielens, removed)
#

set.seed(1, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = edx$rating, times = 1, p = 0.8, list = FALSE)
test <- edx[-test_index,] #20% of data
train <- edx[test_index,] #80% of data

save(validation, edx, test, train, file ="capstone_data.RData") ######################save train & test data for easy loading/re-loading

  }
```
``` {r rowcounts, echo=FALSE}
testrows <- nrow(test)
trainrows <- nrow(train)
validationrows <- nrow(validation)
edxrows <- nrow(edx)
```
The *validation* subset contains approximately 10\% of the data and is set aside for later use; the *edx* subset contains `r edxrows` rows of data; the *train* subset and *test* subsets created from *edx* contain `r trainrows` and `r testrows` rows, respectively.  The *validation* subset just created is set aside for one-time use in validating the final model prior to submission of this paper. 

## Exploratory Data Analysis (EDA)

The structure of the *train* data frame is given as:
\tiny
``` {r echo=TRUE}
str(train)
```
\normalsize
There are `r nrow(train)` observations of six variables in the *train* subset as specified above. All variables are discrete.  The following subsections discuss each of the six variables.  Note that the metrics provided, e.g. counts or percentages, are derived from the *train* subset. \par

### The *movieId* and *title* Fields in the *train* Subset

  The variable *movieID* is a nominal, albeit numerical, value to uniquely identify the movie.  The numerical value of this variable does not indicate any order or interval it simply serves as a reference or name. [In one of his lectures, Professor Iziarry discussed Nominal, Ordinal, Interval and Ratio data. The canonical reference is @stevens01 which is hilarious to read.]  Movie Titles are character strings with names of the movie and (at least some, maybe all, include) the calendar year of release.  Note that some title data is entered in a way to facilitate sorting, e.g. the movie *The Net* is listed as *Net, The*. \par
  

  
The rating for a movie may change over time; for example, I favor black \& white film-noir movies which were once popular in the United States from the late 1930's into the early/mid 1950's, but these days, this genre is generally out-of-favor.  Since the *timestamp* of the movie review is provided (discussed later) which includes the year the rating was made, the 'spread' between the date of the movie release and the date of the movie review might be something utilized to support the models.  As such, a new field will be added to the dataframe, *myr*, which will hold the year of the movie's release. The code creating *myr* will be included as a pre-processor section of the models, including the final model.

### The Movie *genre* Field in the *train* Subset

Movies are classified into single or multiple genres and for some movies the genre is *no genre is listed*. \par
``` {r echo=FALSE}
uniquegenre <- unique(train$genres)
irow <- nrow(uniquegenre)
```


When multiple genre are listed for one movie, they appear to be listed in alphabetic order for each movie. There are
`r irow` unique genre (or combinations of genre) in the *train* data, for example: \par
```{r echo=TRUE}
uniquegenre[1:10]
```




``` {r echo=FALSE, evaluate=TRUE, warning=FALSE,message=FALSE}
library(dplyr)
countbygenre <- train %>% group_by(genres) %>% count(.)
#head(countbygenre$genres)
countbygenre <- data.frame(countbygenre)
#str(countbygenre)
#head(countbygenre)
olist <- order(-countbygenre$n)#
#head(olist)
#sum(olist)
#nrow(train)
genrecounts <- train %>% group_by(genres) %>% count(.) %>% data.frame()
#head(genrecounts)

#nrow(genrecounts)
#sum(genrecounts$n)
sortedcountbygenre <- countbygenre[olist,]
#head(sortedcountbygenre)
#tail(sortedcountbygenre)
summ <- summary(countbygenre$n)
```

 
 ``` {r echo=FALSE}
 #str(genrecounts)
 #nrow(genrecounts)
 genrecounts <- genrecounts %>% mutate(rownbr = as.numeric(rownames(genrecounts)))
 ```
 
 

``` {r eval= TRUE, echo=FALSE, message=TRUE, warning=TRUE}
nors <- str_count(train$genres,"\\|")
nors<- nors +1
x <- (table(nors))
y<- prop.table(x,)
y <- y*100
y<- data.frame(y)
```
str(train)

``` {r genrepcnts, eval= TRUE, echo=FALSE,message=FALSE,warning=FALSE, fig.cap ="Number of Genres by Genre"}

ggplot(data=y,aes(x=nors,y=Freq)) + geom_bar(stat="identity") +
ylab("Percentage of All Movies") +
xlab("Number of Genre In A Movie's Classification")
```
The number of genre assigned to an individual movie is shown above.  The percentage of movies assigned a single genre is `r y$Freq[1]`\%; while those movies with 2 or 3 genres is `r y$Freq[2]+y$Freq[3]`\%.  The 20 single genres in the train subset, listed alphabetically, are:

``` {r eval=TRUE, echo=FALSE, message=FALSE, warning=FALSE}
nors1 <- train %>% filter (str_count(genres,"\\|")==0)
inors1 <- unique(nors1$genres)
#str(inors1)
#sort(inors1)
```
``` {r, eval=TRUE, echo=FALSE}
sort(inors1)
```

``` {r eval=TRUE, echo=FALSE, message=TRUE, warning=TRUE}
nors2 <- train %>% filter (str_count(genres,"\\|")==1)
inors2 <- unique(nors2$genres)
len_inors2 <- length(inors2)
nors3 <- train %>% filter (str_count(genres,"\\|")==2)
inors3 <- unique(nors3$genres)
len_inors3 <- length(inors3)
```
For those movies with 2 genres, there are `r len_inors2` unique genre combinations; for those movies with 3 genres, there are `r len_inors3` unique genre combinations. \par

For each movie with a multiple genres, e.g. "Children|Comedy|Fantasy", because the genre appear to be listed alphabetically it cannot be assumed that this movie is primarily for "Children", secondarily a "Comedy" and thirdly a "Fantasy":  the genre are not ordered by importance or preponderance, but simply ordered alphabetically.  It might be tempting to reduce the number of unique genre to a more manageable number by condensing or summarizing the genre.  For example, a (secondary) vector could be added to the dataframe that would classify each movie by the first two genre entries, e.g. "Children|Comedy|Fantasy" and "Children|Comedy|Fantasy|Sci-Fi|Thriller" would be reclassified as "Children|Comedy."  If the genre were ordered by importance, this might be a reasonable method to test, however, since the genre are simply alphabetized, it does not seem viable. \par



 The above discussion briefly looked at genres and the number of movies within each genre.  The number of movie reviews within each genre can also be examined.  An unordered scatter plot of the number of reviews in each of the `r nrow(genrecounts)` unique genres is shown below.  Those genres with more than 100,000 movie reviews are labeled. Reading down the y-axis: *Drama* is the genre most reviewed, followed by *Comedy* and *Comedy|Romance*, etc. \par
 
``` {r genrecounts1, eval= TRUE, echo=FALSE,message=FALSE,warning=FALSE, fig.cap ="Number of Reviews by Genre"}
ggplot() + geom_point(data=genrecounts,aes(x=1:nrow(genrecounts),y=n)) + 
    ggtitle("Number of Reviews by Genre") +
    #labs(x="Unique Genres",y="Number of Reviews") +
    scale_x_continuous(name="Unique Genres",limits=c(0,800)) +
    scale_y_continuous(name="Number of Reviews",limits=c(0,600000)) +
     geom_text_repel(data=subset(genrecounts, n > 100000),
            aes(rownbr,n,label=genres))
```
Another possible way to deal with the multiple genres might be to reclassify each movie into one of the more predominant genre (or genres): drama, comedy, comedy|romance, etc., down to some specificity level (number of reviews) on the y-axis, above.  This, however, does not seem reasonable.  For the moment, we will leave the genre list as it is. \par

``` {r genrecount, echo=FALSE, evaluate=TRUE, message=FALSE, warning=FALSE}
train <- train %>% mutate(ngenre = str_count(genres,"\\|") + 1)
nbr_of_genre_by_number_of_movies <- train %>% group_by(ngenre) %>% count()
nbr_of_genre_by_number_of_movies <- data.frame(nbr_of_genre_by_number_of_movies)
#str(nbr_of_genre_by_number_of_movies)
#ungroup(nbr_of_genre_by_number_of_movies)
#table(nbr_of_genre_by_number_of_movies$ngenre,nbr_of_genre_by_number_of_movies$n)
```

As shown by the bar-graph, `r figr("genreexpo1",TRUE,type="figure")`, below, the distribution of reviews by genre-type seem to have a very steep 'exponential' range.

``` {r genreexpo1, anchor="Figure", results='asis', eval= TRUE, echo=FALSE,message=FALSE,warning=FALSE, fig.cap ="Distribution of Reviews by Genre"}
library(ggplot2)
ggplot(data=countbygenre,aes(x=reorder(genres,-n),genres,y=n)) + geom_bar(stat="identity") +
ggtitle("Number of Reviews by Genre")  + ylab("Number of Reviews") +  xlab("Genres") +
theme(axis.text.x =element_blank(), axis.ticks.x = element_blank(), axis.text.y=element_blank())
```
In order to get a better feeling for how skewed the data is, the y values are re-plotted on a log10 scale below.  

``` {r genreexpo2, anchor="Figure", results='asis', eval= TRUE, echo=FALSE,message=FALSE,warning=FALSE, fig.caption ="Distribution of Reviews by Genre"}
library(dplyr)
countbygenre <- countbygenre %>% mutate(fill= ifelse(countbygenre$n <= summ[3],"#00BFC4", "#F8766D"))
ggplot(data=countbygenre,aes(x=reorder(genres,n),genres,y=n)) + geom_bar(stat="identity") +
ggtitle("Number of Reviews by Genre - Log10 Scale")  + ylab("Number of Reviews - Log10") +  xlab("Genre Names (Suppressed)") +
scale_y_continuous(trans='log10') +
theme(axis.text.x =element_blank(),axis.ticks.x = element_blank(), axis.text.y=element_blank(),legend.position = "none",  panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        panel.border = element_blank())  
```


Twenty-five percent of the genres have `r summ[2]` or less reviews.  The median of the reviews by genre is `r summ[3]` which means that 50\% of genres have less than `r summ[3]` reviews and 50\% of the genres have more.  The mean of reviews by genre is `r summ[4]` which is significantly greater than the median, showing that the distribution of reviews by genre is heavily skewed to the right -- high-values for several specific genre, e.g. *Drama*, *Comedy*, et al. as shown in the figure above, pull the mean much higher than the median.  The wide range of the number of reviews by genre may contribute to the problem of over-fitting model to the training data set. \par
 


### The Movie *title* and *movieId* Fields in the *train* Subset

```{r,echo=FALSE, evaluate=TRUE, message=FALSE, warning=FALSE}
ratingscounts <- train %>% select(movieId,rating,genres,title) %>% group_by(title) %>% mutate(nbr = n())
#min(ratingscounts$nbr)
ratingscounts <- ratingscounts[order(ratingscounts$nbr),]
#head(ratingscounts)
one_rating <- ratingscounts %>% filter(nbr==1) 
#max(ratingscounts$nbr)
ratingscounts <- ungroup(ratingscounts)
#length(unique(unlist(one_rating[c("title")])))
```


``` {r echo=FALSE, evaluate=TRUE,message=TRUE,warning=TRUE}
nbrmovies <- train %>% group_by(movieId) %>% count(.)
nbrusers <- train %>% group_by(userId) %>% count(.)
```

There are `r nrow(nbrmovies)` unique movies in the *train* subset.  There are `r nrow(nbrusers)` unique reviewers.


### The *userId* Field in the *train* Subset

The number of movie ratings by userId is shown in the plot below.


```{r, echo=FALSE,evaluate=TRUE,message=FALSE,warning=FALSE}
ratings_by_userid <- train %>% select(userId,rating) %>% group_by(userId) %>% summarize(n=n())
ggplot(data=ratings_by_userid,aes(x=userId,y=n)) + geom_bar(stat="identity") +
  ylab("Number of Ratings") +
  xlab("User") +
  ggtitle("Number of Ratings Performed by User") 
```
As shown above, the number of reviews by individual reviewer varies widely.  This will be addressed in the *Regluarization* section of the report, below.

### The *rating* and *timestamp* Fields in the *train* Subset

A function was written to strip the movie release year from the title vector and to place it as the *myr* vector in the *train*, *test*, and *validation* subsets.  The number of ratings by movie release year in the *train* subset is shown below.

``` {r echo=TRUE}

#length(years)
library(dplyr)
right <- function (string, char) {
  yr <- substr(string,nchar(string)-(char-1),nchar(string))
  substr(yr,1,4)
}
```
```{r, echo=FALSE,evaluate=TRUE, message=FALSE,warning=FALSE}

years <- str_count(train$title,"\\(")
year <- (right(train$title,5))
train <- train %>% mutate(myr = year)
year <- data.frame(year)
year_test <- (right(test$title,5))
test <- test %>% mutate(myr = year_test)
year_validation <- (right(validation$title,5))
validation <- validation %>% mutate(myr = year_validation)

#str(year)
yr_count <- year %>% group_by(year) %>% count()
yr_count <- data.frame(yr_count)
#str(yr_count)

title_ans1 <- paste("Number of Reviews by Release Year: (Max= ", max(yr_count$n))
title_ans2 <- paste("Year = ", yr_count$year[which.max(yr_count$n)],")")
title_ans <- paste(title_ans1, title_ans2)
ggplot(data=yr_count,aes(x=year,y=n)) + geom_bar(stat="identity") +
  ylab("Number of Ratings") +
  xlab("Movie Year of Release (1915 to 2008)") +
  ggtitle(paste0(title_ans)) +
  theme(axis.text.x =element_blank(),axis.ticks.x = element_blank(), axis.text.y=element_blank(),legend.position = "none",  panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        panel.border = element_blank()) 
  
```

``` {r echo=FALSE, evaluate=TRUE, message=FALSE, warning=FALSE}
example1 <- train$timestamp[3]
date_info <- as.POSIXct(example1,origin = "1970-01-01",tz="UTC")
earliest <- min(train$timestamp)
latest <- max(train$timestamp)
date_earliest <-as.POSIXct(earliest,origin = "1970-01-01",tz="UTC")
date_latest <- as.POSIXct(latest,origin = "1970-01-01",tz="UTC")
```
The *timestamp* for each review, e.g. `r example1`, counts the seconds since midnight Coordinated Universal Time (UTC) since January 1, 1970 [@timestamp01].  For this example, the date/time is `r date_info`.  The earliest date/time of a movie review in the train subset is `r date_earliest`; the date/time of the last movie review in the subset is `r date_latest`.  It is assumed that movie reviewers may be located world-wide, so without knowing the geographic location (timezone) of a particular reviewer, not much can be made of the *hour* data; whether a particular review is made late in the day or early in the morning cannot be determined.  Using the functions contained in the *lubridate* library, the date/time will be parsed into the following component parts: year(numeric), month(numeric:1-12), and day-of-the-week(numeric:1-7, with 1=Sunday) each of which will be added to the *train* dataframe.  Note that any fields added to a training data set and used by a model must also be performed on the testing and validation sets prior to evaluating the performance of the model. \par


The number of movie ratings by day-of-the-week is shown below.

```{r dayofweek, echo=FALSE, evaluate=TRUE, warning=FALSE, message=FALSE}
library(dplyr)
library(lubridate)
date_info <- as.POSIXct(train$timestamp,origin = "1970-01-01",tz="UTC")
rev_year <- year(date_info)
rev_month <- month(date_info)
rev_day <- wday(date_info)
train <- train %>% mutate(wday = as.factor(rev_day))
rating_by_day <- train %>% select(wday,rating) %>% group_by(wday) %>% summarize(n=n())
#rating_by_day
#str(rating_by_day)

train <- train %>% mutate(ryr = rev_year)

library(lubridate)
date_info <- as.POSIXct(test$timestamp,origin = "1970-01-01",tz="UTC")
rev_year_test <- year(date_info)
#head(rev_year_test)
library(dplyr)
test <- test %>% mutate(ryr = rev_year_test)
#str(train)
date_info <- as.POSIXct(validation$timestamp,origin = "1970-01-01",tz="UTC")
rev_year_validation <- year(date_info)
validation <- validation %>% mutate(ryr = rev_year_validation)

train <- train %>% mutate(delta_yr = as.numeric(ryr)-as.numeric(myr))
test <- test %>% mutate(delta_yr = as.numeric(ryr)-as.numeric(myr))
validation <- validation %>% mutate(delta_yr = as.numeric(ryr)-as.numeric(myr))

ggplot(data=rating_by_day,aes(x=wday,y=n)) + geom_bar(stat="identity") +
  ylab("Number of Ratings") +
  xlab("Day of Week (1 = Sunday)")

  
```


The number of ratings by day-of-the-week is shown above.  I would have thought that a disporportionate number of reviews would have been written early in the week -- based on a weekend of movie viewing -- but it seems the distribution is fairly constant, so there is probably not much to be gained from including the weekday that the review was written in a model. \par

The mean rating by day of the week is also fairly constant at 3.5.  I did not see a reason to include that plot, but below are seven plots showing the ratings distribution by day from which you can see that the shapes of the distributions are more-or-less constant over the span of days.  Again, there seems to be no need to consider the day of the week in a model.

```{r ratingdayofweek, echo=FALSE, evaluate=TRUE, warning=FALSE, message=FALSE}
library(dplyr)
library(ggplot2)
rating_by_day <- train %>% select(wday,rating) %>% group_by(wday,rating) %>% summarize(n=n())
#rating_by_day
#str(rating_by_day)

ggplot(data=rating_by_day,aes(x=rating,y=n)) + geom_bar(stat="identity") +
  ylab("Number of Ratings") +
  xlab("Rating Value") +
  ggtitle("Distribution of Rating Values by Day of the Week, Sunday=1") +
  facet_wrap(.~wday)
  ```

Although using the time of the day (AM/PM) is not possible because we do not know the geographic location, and because the ratings dstirbutions are fairly constant across the seven days of the week as shown above, we can probably only reply on the year of the review,  So *ryr*, review year, is extracted from the timestamp and included in the *train*, *test* and *validation* subsets.
  
  
# Results
## Evaluation Metric Defined
ML results may be evaluated in various ways as described in @irizarry02: Confusion Matrix, Sensitivity, Selectivity, F-Score, etc.  For this project, Root Mean Square Error (RMSE) is utilized.  The RMSE is calculated with:
\[
RMSE = \sqrt{(\frac{1}{N})\sum_{u=1,i=1}^{N,N}(\hat{y}_{u,i} - y_{u,i})^{2}}
\]

## Preparation of the Subset DataFrames

The *train* and *test* dataframes will now be modified as discussed above.  Specifically, fields *myr*, *ryr*, *wday* for movie year (integer), review year (integer), and day of the week (factor) will be added to the dataframes.  In additon the rating provided to each move, will be converted to a factor. \par
Following @irizarry03 a RMSE function will be coded for use in generating results from each of the models tested.  The code of the RMSE calculations has been modified to ignore NA values in either vector (*true_ratings* or *predicted_ratings*) by using the *complete.cases* built-in function.  
``` {r RSMEequation, echo=TRUE, evaluate=TRUE}
RMSE <- function(true_ratings, predicted_ratings){
  tmp <- data.frame(cbind(true_ratings, predicted_ratings))
  tmp <- tmp[complete.cases(tmp),]
  sqrt(mean((tmp$true_ratings - tmp$predicted_ratings)^2))
}
```
```{r checks, echo=FALSE, evluate=TRUE}
test<- test %>%
  semi_join(train, by="movieId") %>%
  semi_join(train, by="userId")
```
## Naive Models
### Model 1: Naive Guess

As a first model the naive guess is utilized. Movie ratings are predicted simply based on the average rating, *mu_hat,* calculated from the train subset.  For movie = i and user/rater = u, the equation to predict the rating, Y, is a simple linear function:

\[
Y_{u,i} = \mu + \epsilon_{u,i}
\]

```{r naive, echo=TRUE}
mu_hat <- mean(train$rating)
```
Across the train subset, mu_hat = `r mu_hat`.

```{r naive_rmse, echo=FALSE, evaluate=TRUE}
rmse_model1 <- RMSE(test$rating,mu_hat) #use function
```
The RMSE for the naive model is `r rmse_model1` which is not too good, but the RMSE from this model may serve as an upper limit.
Again, following @irizarry03 we will create a results table to hold the results of the various models.


```{r, echo=TRUE,evaluate=TRUE,warning=TRUE,message=TRUE}
rmse_results <- data.frame(Model_Name = "Model 1: Naive Guess", RMSE = rmse_model1)
```


### Model 2: Naive Guess With *movieId* Bias

@irizarry03 discusses modifying the naive guess model by adding a bias factor.  Bias is the average above mu_hat that movies are rated when grouped by movieId.  In other words for a given movie (*moveId*) the difference between each actual rating and mu_hat is calculated and these differences are then averaged for each *movieId*.

``` {r, echo=TRUE, evaluate=TRUE, message=TRUE, warning=TRUE}
movie_avgs <- train %>%
  group_by(movieId) %>%
  summarize(b_i_hat = mean(rating-mu_hat))
qplot(b_i_hat, data= movie_avgs, bins=10, color = I("black"))
```
The plot shows that some *movieId*s are above mu_hat (where $b_i$ is greater than zero), but more seem lower than mu_hat (where $b_i$ is less than zero).  We can now use the formula
\[
Y_{u,i} = \mu + b_{i} + \epsilon_{u,i}
\]
and evaluate the performance of this slightly modified model.

```{r model2, echo=TRUE, evaluate=TRUE}
library(dplyr)
predicted_ratings <- mu_hat + test %>%
  left_join(movie_avgs, by='movieId') %>%
  pull(b_i_hat)
rmse_model2 <-RMSE(test$rating,predicted_ratings)
```
With this slightly modified model, an RMSE of `r rmse_model2` is achieved which is approximately 11\% better than the simple naive model.  We will now store these results in the results table.


```{r, echo=TRUE,evaluate=TRUE,warning=TRUE,message=TRUE}
rmse_results <- rbind(rmse_results,data.frame(Model_Name = "Model 2: Naive Guess with movieId Bias", RMSE = rmse_model2))
```



### Model 3: Naive Guess With *movieId* and *userId* Biases
In a similar way, we can attempt to account for *userId* bias, meaning the average ratings by a specific user above/below the average rating across all movies.
\[
Y_{u,i} = \mu + b_{i} + b_{u} + \epsilon_{u,i}
\]

```{r twobiases, echo=TRUE, evaluate=TRUE, message= TRUE, warning=TRUE}
user_avgs <- train %>%
  left_join(movie_avgs, by='movieId') %>%
  group_by(userId) %>%
  summarize(b_u_hat = mean(rating - mu_hat - b_i_hat))

predicted_ratings <- test%>%
  left_join(movie_avgs, by='movieId') %>%
  left_join(user_avgs, by='userId') %>%
  mutate(pred = mu_hat + b_i_hat + b_u_hat) %>%
  pull(pred)
rmse_model3 <- RMSE(test$rating,predicted_ratings)

```
The RMSE for this model is `r rmse_model3` which is `r (rmse_model2-rmse_model3)*100/rmse_model2`\% better than Model 2.
predicted_ratings


```{r, echo=FALSE,evaluate=TRUE,warning=FALSE,message=FALSE}
rmse_results <- rbind(rmse_results,data.frame(Model_Name = "Model 3: Naive Guess with movieId and userId Biases", RMSE = rmse_model3))
```
rmse_results

## Regularization
### Model 4: Regularization: Number of Reviews/Movie
Adding the *movieId* and *userId* bias adjustments improved RMSE, but the results are still not very good.  If we look at the movies rated best and worse, but sets contain mostly obscure movies which were rated by only a few users.  For example, the top 10 rated movies are:

```{r topmovies,echo=TRUE,evalutate=TRUE}
#connect movieId to movietitle
movie_titles <- edx %>%
  select(movieId, title) %>%
  distinct()
#
#find 10 best movies
movie_avgs %>% left_join(movie_titles, by="movieId") %>%
  arrange(desc(b_i_hat)) %>%
  slice(1:10) %>%
  pull(title)
```
These are fairly obscure -- at least to me.  The 10 worst rated movies are:
``` {r worstmovies, echo=FALSE, evaluate=TRUE}
movie_avgs %>% left_join(movie_titles, by="movieId") %>%
  arrange(b_i_hat) %>%
  slice(1:10) %>%
  pull(title)
```
Again, these movies appear to be obscure, which raises the question: how may reviews did these 'best' and 'worst' movies receive?  How often were they rated?

``` {r countbest, echo=FALSE, evaluate=TRUE}
train %>% count(movieId) %>%
  left_join(movie_avgs, by="movieId") %>%
  left_join(movie_titles, by="movieId") %>%
  arrange(desc(b_i_hat)) %>%
  slice(1:10) %>%
  pull(n)
```
These 'best' movies only received a few ratings each.

``` {r countworst, echo=TRUE, evaluate=TRUE}
train %>% count(movieId) %>%
  left_join(movie_avgs, by="movieId") %>%
  left_join(movie_titles, by="movieId") %>%
  arrange(b_i_hat) %>%
  slice(1:10) %>%
  pull(n)
```
These 'worst' movies only received a few ratings each.  In the EDA section above we explored the number of ratings by genre, etc., and saw a wide variation.  Here, in both the best and worst movie sets, the number of ratings is very small.  How can the number of ratings for a given movie be factored into the over ML model?  One way is to add a $\lambda$ parameter that control a penalty function.  The task is to find a $\lambda$ that minimizes
\[
\hat{b_i} = \frac{1}{\lambda + n_i} \sum_{u=1}(Y_{u,i} - \mu)
\]
Note that n is the number of reviews for a particular movie (i), and that for large $n_i$, $\lambda + n_i \approx n_i$, while for movies with a small number of reviews where $n_i$ is small, greater $\lambda$ will lower $\hat{b_i}(\lambda)$. \par

Of course, choosing the proper $\lambda$ without cross-validation would be difficult.  Cross-validation for parameter tuning can be utilized to test a sequence of $\lambda$ parameters, RMSE can be calculated for each and the optimal value can be chosen.

``` {r crossvalidation, echo=TRUE, evaluate=TRUE, message=TRUE, warning=TRUE}
lambdas <- seq(0, 10, 0.25)
mu <- mean(train$rating)
just_the_sum <- train %>% 
  group_by(movieId) %>% 
  summarize(s = sum(rating - mu), n_i = n())
rmses <- sapply(lambdas, function(l){
  predicted_ratings <- test %>% 
    left_join(just_the_sum, by='movieId') %>% 
    mutate(b_i = s/(n_i+l)) %>%
    mutate(pred = mu + b_i) %>%
    .$pred
  return(RMSE(predicted_ratings, test$rating))
})
qplot(lambdas, rmses)  
min_lambda1 <- lambdas[which.min(rmses)]
min_reg1_rmses <- min(rmses)

```
The plot above shows the relationship between various lambda values and the RMSE which results for each which run against the *test* subset.  The lambda associated with the minimum RMSE is $\lambda_1 = `r min_lambda1`$ which results in an $RMSE = `r round(min_reg1_rmses,digits=4)`$. This is the RMSE when regularizing on the number reviews per movie.  We will store this value and try to fine tune this model further by also regularizing the data based on the number of reviewers.

```{r, echo=FALSE,evaluate=TRUE,warning=FALSE,message=FALSE}
rmse_results <- rbind(rmse_results,data.frame(Model_Name = "Model 4: Regularize Reviews/Movie", RMSE = min_reg1_rmses))
```


### Model 5: Regularization: Reviews/Movie and Reviewers/Movie
Just as the number of reviews per movie varied widely, the number of reviewers by average rating also varies widely. As shown below only a few raters gave low or high ratings, the majority gave a rating of approximately 3.5. In order to account for this effect, we can again employ the method of regularization to adjust the rating depending on how many raters were involved at that rating level across all movies.  

```{r usersbyrating, echo=FALSE, evaluate=TRUE, message=FALSE, warning=FALSE}
train %>% 
  group_by(userId) %>% 
  summarize(raters_hat = mean(rating)) %>% 
  ggplot(aes(raters_hat)) + 
  geom_histogram(bins = 50, color = "green")+
  labs(title="Number of Raters by Average Rating") +
  xlab("Average Rating") +
  ylab("Number of Raters")
```
We can use the same process as before to identify the best lambda via cross-validation to adjust for both of these bias-effects.




``` {r crossvalidation_raters, echo=TRUE, evaluate=TRUE, message=TRUE, warning=TRUE}
library(ggplot2)
library(dplyr)
lambdas <- seq(0, 10, 0.25)
  
  rmses <- sapply(lambdas, function(l){
    
    mu_hat <- mean(train$rating)
    
    b_i_hat <- train %>% 
      group_by(movieId) %>%
      summarize(b_i_hat = sum(rating - mu_hat)/(n()+min_lambda1))
    
    b_u_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      group_by(userId) %>%
      summarize(b_u_hat = sum(rating - b_i_hat - mu_hat)/(n()+l))
    
    predicted_regularization <- test %>% 
      left_join(b_i_hat, by = "movieId") %>%
      left_join(b_u_hat, by = "userId") %>%
      mutate(pred = mu_hat + b_i_hat + b_u_hat) %>%
      .$pred
    
    return(RMSE(test$rating,predicted_regularization))
  })
  
  qplot(lambdas, rmses)  
  min_lambda2 <- lambdas[which.min(rmses)]
min_reg2_rmses <- min(rmses)
```

From the plot above, the minimum RMSE of `r round(min_reg2_rmses,digits=4)` occurs at $\lambda_2 = `r min_lambda2`$.  Again, remember these results, like the ones above simply test the various models against the *test* set.  We will now add this result to the rmse_results table.
```{r, echo=FALSE,evaluate=TRUE,warning=FALSE,message=FALSE}
rmse_results <- rbind(rmse_results,data.frame(Model_Name = "Model 5: Regularize Reviews/Movie and Reviews/Movie", RMSE = min_reg2_rmses))
```

### Model 6: Regularization: Review/Movie and Reviewers/Movie and Delta Date
In the discussion above, the year of the movie's release and the year of the review were discussed.  Many films were released decades prior to being rated by anyone, others (contemporaneous with MovieLens) were rated upon release by some raters and years after release by others.  Vectors of the movie release year, *myr* and the review year, *ryr* were added to the *train* subset.  It might be interesting to see what impact the addition of a $\lambda_yr$ parameter to account for the difference between *myr* and *ryr*.    To do this we need to add those two vectors to the *test* subset, too; and if we decide to use this model, those vectors must also be added to the *validation* subset, as well.  I note that this difference should be non-negative, but in looking at the data in the *train* subset, there are some negative numbers which I conclude originated from missing or corrupted data.  I decided to ignore these few problems for the moment, but this should be investigated later.



``` {r crossvalidation_delta_yr, echo=TRUE, evaluate=TRUE, message=TRUE, warning=TRUE}
library(ggplot2)
library(dplyr)
lambdas <- seq(830, 845, .5)
  
  rmses <- sapply(lambdas, function(l){
    
    mu_hat <- mean(train$rating)
    
    b_i_hat <- train %>% 
      group_by(movieId) %>%
      summarize(b_i_hat = sum(rating - mu_hat)/(n()+min_lambda1))
    
    b_u_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      group_by(userId) %>%
      summarize(b_u_hat = sum(rating - b_i_hat - mu_hat)/(n()+min_lambda2))
    
    b_yr_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      left_join(b_u_hat, by= "userId") %>%
      group_by(delta_yr) %>%
      summarize(b_yr_hat = sum(rating - b_i_hat - b_u_hat - mu_hat)/(n()+l))
    
    predicted_regularization <- test %>% 
      left_join(b_i_hat, by = "movieId") %>%
      left_join(b_u_hat, by = "userId") %>%
      left_join(b_yr_hat, by = "delta_yr") %>%
      mutate(pred = mu_hat + b_i_hat + b_u_hat + b_yr_hat) %>%
      .$pred
    
    return(RMSE(test$rating,predicted_regularization))
  })
  
  qplot(lambdas, rmses)  
  min_lambda3 <- lambdas[which.min(rmses)]
  min_reg3_rmses <- min(rmses)
```

This model was cross-validated several times with different sequential $\lambda$ values.
This model results in a minimum RMSE of `r round(min_reg3_rmses,digits=4)` which occurs at $lambda_{yr} = `r min_lambda3`$.


```{r, echo=FALSE,evaluate=TRUE,warning=FALSE,message=FALSE}
rmse_results <- rbind(rmse_results,data.frame(Model_Name = "Model 6: Regularize Reviews/Movie and Reviews/Movie and Delta_Year", RMSE = min_reg3_rmses))
```


At least an inflection point was found, so it can be accepted, still the RSME may not be 'the best' and the RSME may result from overfitting.  We are in the dark.  This RSME is pretty good, but how will the model fare with the *validation* subset?  Maybe it is over-fitted, who knows.

## Regularization with a Hat On

In processing the *delta_yr* data for Model 6, it was noticed that when the left-Join was completed using *by = "delta_year"* that some *delta_year* entries in the *test* set were not available in the *train* set.  This led to considering a method that would 'fill-in' the mean value of *b_yr_hat* to replace each NA that was created by the left_join for that particular vector using code like: 

```{r echo=TRUE, evaluate=FALSE, warning=FALSE, message=FALSE}
# calculate the mean of b_yr_hat over the train subset
mean_b_yr <- mean(train$b_yr_hat)
# for values in the test subset that remain NA after the left_join, 
# replace with the mean value from the train subset
test$b_yr_hat[is.na(test$b_yr_hat)] <- mean_b_yr 
```
We can refer to this replacement of NAs within the *test* subset with the mean value from the *train* subset as 'filling in the blanks.'  Indeed, I have not examined the NA population in the *test* subsets after the b_u_hat left_join, or after the b_i_hat left_join.  So maybe we should rerun Model 6 with all the various 'b' NA values 'filled-in' with the respective 'b-means' and evaluate any change in RMSE.  We already know the three $\lambda$ values so cross-validation is not needed, and this model will execute rather quickly.  Essentially we calculate the mean for each of *b_u_hat*, *b_i_hat*, and *b_yr_hat* and use them to replace any NA values in those vectors.  With this method, every observation will have a value for these three vectors, even if it is 'only' the mean-value.


### Model 7: Model 6 Regularization with Fill In the Blanks

```{r, echo=TRUE, evaluate=TRUE, message=TRUE, warning=TRUE}
 
    
    mu_hat <- mean(train$rating)
    
    b_i_hat <- train %>% 
      group_by(movieId) %>%
      summarize(b_i_hat = sum(rating - mu_hat)/(n()+2.5))
      
    bi_mean <- b_i_hat %>% ungroup() %>% mean(b_i_hat)
    
    b_u_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      group_by(userId) %>%
      summarize(b_u_hat = sum(rating - b_i_hat - mu_hat)/(n()+5.0))
      
    bu_mean <- b_u_hat %>% ungroup() %>% mean(b_u_hat)
    
    b_yr_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      left_join(b_u_hat, by= "userId") %>%
      group_by(delta_yr) %>%
      summarize(b_yr_hat = sum(rating - b_i_hat - b_u_hat - mu_hat)/(n()+842.50))
      
    byr_mean <- b_yr_hat %>% ungroup() %>% mean(b_yr_hat)
    
    final_test <- test %>% 
      left_join(b_i_hat, by = "movieId") %>%
      left_join(b_u_hat, by = "userId") %>%
      left_join(b_yr_hat, by = "delta_yr")
      
#Here we replace any NA value in the three bias vectors with its mean value  
      final_test$b_u_hat[is.na(final_test$b_u_hat)]   <- bu_mean
      final_test$b_i_hat[is.na(final_test$b_i_hat)]   <- bi_mean
      final_test$b_yr_hat[is.na(final_test$b_yr_hat)] <- byr_mean
      
    
    predicted_regularization <- final_test %>% mutate(pred = mu_hat + b_i_hat + b_u_hat + b_yr_hat) %>%
      .$pred
   
    
model7_results <- RMSE(test$rating,predicted_regularization)
```





```{r, echo=FALSE,evaluate=TRUE,warning=FALSE,message=FALSE}
rmse_results <- rbind(rmse_results,data.frame(Model_Name = "Model 7: Regularization With Fill In the Blanks", RMSE = model7_results))

model7_results
```


## Summary of RMSE Results For Each Model

In order to choose among these 7 models, we will review the RMSE of each:

```{r, echo=FALSE,evaluate=TRUE,message=FASLE,warning=FALSE}
knitr::kable(rmse_results)
```

It is hard to determine the best model based on RMSE alone as the minimal RMSE may have resulted not from a robust model, but from an over-fitted one.  It looks like the options are between Model 6 and Model 7 with RMSE of 0.864 and 0.865, respectively.  I think I will go with Model 7 because I like the 'fill in the blanks' method it utilizes and I am not too sure what to expect with the *validation* subset!



## Final Model Performance on the *validation* Subset


```{r, echo=TRUE, evaluate=TRUE, message=TRUE, warning=TRUE}
 
    
    mu_hat <- mean(train$rating)
    
    b_i_hat <- train %>% 
      group_by(movieId) %>%
      summarize(b_i_hat = sum(rating - mu_hat)/(n()+2.5))
      
    bi_mean <- b_i_hat %>% ungroup() %>% mean(b_i_hat)
    
    b_u_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      group_by(userId) %>%
      summarize(b_u_hat = sum(rating - b_i_hat - mu_hat)/(n()+5.0))
      
    bu_mean <- b_u_hat %>% ungroup() %>% mean(b_u_hat)
    
    b_yr_hat <- train %>% 
      left_join(b_i_hat, by="movieId") %>%
      left_join(b_u_hat, by= "userId") %>%
      group_by(delta_yr) %>%
      summarize(b_yr_hat = sum(rating - b_i_hat - b_u_hat - mu_hat)/(n()+842.50))
      
    byr_mean <- b_yr_hat %>% ungroup() %>% mean(b_yr_hat)
    
    final_test <- test %>% 
      left_join(b_i_hat, by = "movieId") %>%
      left_join(b_u_hat, by = "userId") %>%
      left_join(b_yr_hat, by = "delta_yr")
      
#Here we replace any NA value in the three bias vectors with its mean value  
      final_test$b_u_hat[is.na(final_test$b_u_hat)]   <- bu_mean
      final_test$b_i_hat[is.na(final_test$b_i_hat)]   <- bi_mean
      final_test$b_yr_hat[is.na(final_test$b_yr_hat)] <- byr_mean
      
    
    predicted_regularization <- final_test %>% mutate(pred = mu_hat + b_i_hat + b_u_hat + b_yr_hat) %>%
      .$pred
   
    
model7_results <- RMSE(validation$rating,predicted_regularization)
```






# Conclusions

In this ML exercise, I investigated several models for movie recommendations based on the MovieLens data.  There are many other models that could have been tested, and should be tested prior to reaching a conclusion, however based on the models examined the ML with regularization seemed to be the best choice.  Regularization, to minimize bias in under/over-weighted samples, was performed on movieId and userId.  The year the movie was reviewed was unbundled and retreived from the *timestamp* and added to each subset as *ryr*.  The year the movie was released was stripped from the *title* and added to each subset as *myr*. A field, *delta_yr* was then added to the three subsets to hold the difference between *ryr* and *myr*.  This was also utilized for regularization.  Finally, I decided to fill-in any blank bias terms in the regularization model with the mean of that particular bias, e.g. *movieId*, *reviewer*, *delta_yr* which I call Model 7: Model 6 With All Hats!  Based on the RMSE achieved, this was was selected as the final model.

When running the final model against the *validation* subset an RMSE =    was achieved.  

Also, this is my first time writing an rmarkdown report.  I tried to get cross-referencing to work, but was unsuccessful.  I did at least get the table of contents and the references processes to work.  I need to experiment with kable for better looking tables.  In the past most of my reports have been written in Latex. \par

One concern is the ability of R to actually process large/larger amounts of data.  I would have liked to perform a KNN analysis of the data, but R (at least on my system) would not cooperate even on the smaller train subset.  I am not sure if that is a limitation of R, or my PC, or both.  I will need to look in this question, although at present my processing of (mainly) survey data is on the order of 18K observations of approximately 135 variables which fits easily into my current analytical processes.  Another area I need to explore concerns the processing of categorical data and the requirement for converting them to factors for some ML algorithms.  When are factors vs. categorical variables required.  Another area I want to explore is the normalization of data prior to ML: which algorithms require it, which don't; and should the test subset then be normalized prior to testing the model -- I assume the answer is yes.

After this course I plan to collect the end-pages from each of the 3 spiral-bound notebooks I have used during this course where I have noted 'things for further study/investigation.'  There are a lot of them!  I enjoyed the course very much.  
Thank you.

# References






