############### Utility functions ###############
libraryRequireInstall = function(packageName, ...)
{
  if(!require(packageName, character.only = TRUE))
    warning(paste("*** The package: '", packageName, "' was not installed ***", sep=""))
}

libraryRequireInstall("XML")
libraryRequireInstall("htmlwidgets")

internalSaveWidget <- function(widget, fname)
{
  tempFname = paste(fname, ".tmp", sep="")
  htmlwidgets::saveWidget(widget, file = tempFname, selfcontained = FALSE)
  FlattenHTML(tempFname, fname)
}

FlattenHTML <- function(fnameIn, fnameOut)
{
  # Read and parse HTML file
  # Embed all js and css files into one unified file

  if(!file.exists(fnameIn))
    return(FALSE)

  dir = dirname(fnameIn)
  html = htmlTreeParse(fnameIn, useInternal = TRUE)
  top = xmlRoot(html)

  # extract all <script> tags with src value
  srcNode=getNodeSet(top, '//script[@src]')
  for (node in srcNode)
  {
    b = xmlAttrs(node)
    fname = file.path(dir, b['src'])
    alternateSrc = FindSrcReplacement(fname)
    if (!is.null(alternateSrc))
    {
      s = alternateSrc
      names(s) = 'src'
      newNode = xmlNode("script",attrs = s)
      replaceNodes(node, newNode)
    }else{
      str=ReadFileForEmbedding(fname);
      if (!is.null(str))
      {
        newNode = xmlNode("script", str, attrs = c(type = "text/javascript"))
        replaceNodes(node, newNode)
      }
    }
  }

  # extract all <link> tags with src value
  linkNode=getNodeSet(top, '//link[@href]')
  for (node in linkNode)
  {
    b = xmlAttrs(node)
    fname = file.path(dir, b['href'])
    str = ReadFileForEmbedding(fname, FALSE);
    if (!is.null(str))
    {
      newNode = xmlNode("style", str)
      replaceNodes(node, newNode)
    }
  }

  saveXML(html, file = fnameOut)
  return(TRUE)
}

ReadFileForEmbedding <- function(fname, addCdata = TRUE)
{
  data = ReadFullFile(fname)
  if (is.null(data))
    return(NULL)

  str = paste(data, collapse ='\n')
  if (addCdata) {
    str = paste(cbind('// <![CDATA[', str,'// ]]>'), collapse ='\n')
  }
  return(str)
}

ReadFullFile <- function(fname)
{
  if(!file.exists(fname))
    return(NULL)

  con = file(fname, open = "r")
  data = readLines(con)
  close(con)
  return(data)
}

FindSrcReplacement <- function(str)
{
  # finds reference to 'plotly' js and replaces with a version from CDN
  # This allows the HTML to be smaller, since this script is not fully embedded in it
  str <- iconv(str, to="UTF-8")
  pattern = "plotlyjs-(\\w.+)/plotly-latest.min.js"
  match1=regexpr(pattern, str)
  attr(match1, 'useBytes') <- FALSE
  strMatch=regmatches(str, match1, invert = FALSE)
  if (length(strMatch) == 0) return(NULL)

  pattern2 = "-(\\d.+)/"
  match2 = regexpr(pattern2, strMatch[1])
  attr(match2, 'useBytes') <- FALSE
  strmatch = regmatches(strMatch[1], match2)
  if (length(strmatch) == 0) return(NULL)

  # CDN url is https://cdn.plot.ly/plotly-<Version>.js
  # This matches the specific version used in the plotly package used.
  verstr = substr(strmatch, 2, nchar(strmatch)-1)
  str = paste('https://cdn.plot.ly/plotly-', verstr,'.min.js', sep='')
  return(str)
}
#################################################

############### Library Declarations ###############
libraryRequireInstall("plotly");
libraryRequireInstall("jsonlite");
libraryRequireInstall("rpivotTable");
####################################################

############### HTML Entity Encoding for Greek Characters ###############
# Function to convert characters to HTML numeric entities
# This solves the encoding problem by making Greek characters pure ASCII
toHtmlEntities <- function(str) {
  if(is.na(str) || is.null(str) || nchar(str) == 0) return(str)

  # Convert string to UTF-8 to ensure proper encoding
  str <- enc2utf8(as.character(str))

  # Split into individual characters
  chars <- strsplit(str, "")[[1]]

  # Convert each character to HTML entity if it's non-ASCII (code > 127)
  result <- sapply(chars, function(ch) {
    code <- utf8ToInt(ch)
    if(code > 127) {
      paste0("&#", code, ";")
    } else {
      ch
    }
  })

  paste(result, collapse = "")
}

# Apply HTML entity encoding to all Values
if(exists("Values")) {
  Values <- as.data.frame(lapply(Values, function(x) {
    if(is.character(x) || is.factor(x)) {
      sapply(as.character(x), toHtmlEntities, USE.NAMES = FALSE)
    } else {
      x
    }
  }), stringsAsFactors = FALSE)

  # Also encode column names
  colnames(Values) <- sapply(colnames(Values), toHtmlEntities, USE.NAMES = FALSE)
}
####################################################

################### Actual code ####################
initial_renderer <- "Table";
initial_agg <- "Count";
initial_vals <- "";
initial_row <- colnames(Values)[1];
initial_column <- colnames(Values)[2];
initial_row_order <- "key_a_to_z";
initial_col_order <- "key_a_to_z";

if (!exists("settings_rpivottable_params_limitDecimalPlaces"))
{
    settings_rpivottable_params_limitDecimalPlaces = 2;
}

if (exists("internal_settings_settings"))
{
	user_persisted_settings <- fromJSON(internal_settings_settings);
	
	initial_renderer <- user_persisted_settings$rendererName;
	initial_agg <- user_persisted_settings$aggregatorName;
	initial_vals <- user_persisted_settings$vals;
	initial_row <- user_persisted_settings$rows;
	initial_column <- user_persisted_settings$cols;
	initial_row_order <- user_persisted_settings$rowOrder;
	initial_col_order <- user_persisted_settings$colOrder;
}

# set decimal places since we currently cannot get formatting for R visuals
#idx <- sapply(Values, class)=="numeric"
#Values[, idx] <- lapply(Values[, idx], formatC, digits = as.numeric(settings_rpivottable_params_limitDecimalPlaces), format = "f")

# build pivot table
p <- rpivotTable(Values, 
		rows = initial_row, 
		cols = initial_column,
        vals = initial_vals,
		aggregatorName  = initial_agg,
		rendererName = initial_renderer,
		rowOrder = initial_row_order,
		colOrder = initial_col_order,
		width = "100%", 
		height = "95vh"
	);

# adjust padding to use entire container
p$sizingPolicy$browser$padding = 0

####################################################

############# Create and save widget ###############
internalSaveWidget(p, 'out.html');
####################################################
