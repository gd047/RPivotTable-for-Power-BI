source('./r_files/flatten_HTML.r')

############### Library Declarations ###############
libraryRequireInstall("plotly");
libraryRequireInstall("jsonlite");
libraryRequireInstall("rpivotTable");
####################################################

############### UTF-8 Encoding Setup ###############
# Ορισμός UTF-8 encoding για σωστή εμφάνιση ελληνικών χαρακτήρων
Sys.setlocale("LC_ALL", "en_US.UTF-8")
options(encoding = "UTF-8")

# Διάβασε τα Values με σωστό encoding
if(exists("Values")) {
  # Μετατροπή όλων των character columns σε UTF-8
  Values <- as.data.frame(lapply(Values, function(x) {
    if(is.character(x) || is.factor(x)) {
      # Προσπάθεια μετατροπής από διάφορα encodings
      result <- tryCatch({
        # Δοκιμή να μετατρέψουμε από Windows-1253 (Greek Windows encoding)
        converted <- iconv(as.character(x), from = "CP1253", to = "UTF-8")
        # Αν επιστρέψει NA, δοκιμάζουμε με το τρέχον encoding
        if(all(is.na(converted))) {
          iconv(as.character(x), to = "UTF-8")
        } else {
          converted
        }
      }, error = function(e) {
        # Αν αποτύχει, απλά μετατρέπουμε σε UTF-8
        iconv(as.character(x), to = "UTF-8")
      })
      result
    } else {
      x
    }
  }), stringsAsFactors = FALSE)

  # Διατήρηση των ονομάτων των στηλών με UTF-8 encoding
  colnames(Values) <- iconv(colnames(Values), to = "UTF-8")
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

# Διόρθωση του HTML για UTF-8 encoding
html_file <- file('out.html', open = "r", encoding = "UTF-8")
html_content <- readLines(html_file, encoding = "UTF-8", warn = FALSE)
close(html_file)

# Προσθήκη UTF-8 meta tag αν δεν υπάρχει
if(!any(grepl("charset.*utf-8", html_content, ignore.case = TRUE))) {
  meta_line <- which(grepl("<head>", html_content, ignore.case = TRUE))
  if(length(meta_line) > 0) {
    html_content <- append(html_content,
      '<meta charset="UTF-8">',
      after = meta_line[1])
  }
}

# Εγγραφή με UTF-8 encoding
html_out <- file('out.html', open = "w", encoding = "UTF-8")
writeLines(html_content, html_out, useBytes = FALSE)
close(html_out)
####################################################
