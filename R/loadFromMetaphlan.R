#' Import Metaphlan results to \code{TreeSummarizedExperiment}
#
#' @param file a single \code{character} value defining the file
#'   path of the Metaphlan file. The file must be in merged Metaphlan format.
#'
#' @param sample_meta a single \code{character} value defining the file
#'   path of the sample metadata file. The file must be in \code{tsv} format
#'   (default: \code{sample_meta = NULL}).
#'   
#' @param phy_tree a single \code{character} value defining the file
#'   path of the phylogenetic tree.
#'   (default: \code{phy_tree = NULL}).
#'   
#' @param ... additional arguments:
#' \itemize{
#'   \item{\code{abund_values}:} {A single character value for naming 
#'   \code{\link[SummarizedExperiment:SummarizedExperiment-class]{assay}} 
#'   (default: \code{abund_values = "counts"})}
#'   \item{\code{removeTaxaPrefixes}:} {\code{TRUE} or \code{FALSE}: Should
#'     taxonomic prefixes be removed? (default:
#'     \code{removeTaxaPrefixes = FALSE})}
#' }
#'
#' @details
#' Import Metaphlan results. Input must be in merged Metaphlan format.
#' Data is imported so that data at the lowest rank is imported as a 
#' \code{TreeSE} object. Data at higher rank is imported as a
#' \code{SE} objects which are stored to \code{altExp} of
#' \code{TreeSE} object.
#'
#' @return  A
#' \code{\link[TreeSummarizedExperiment:TreeSummarizedExperiment-class]{TreeSummarizedExperiment}}
#' object
#'
#' @name loadFromMetaphlan
#' @seealso
#' \code{\link[=makeTreeSummarizedExperimentFromPhyloseq]{makeTreeSummarizedExperimentFromPhyloseq}}
#' \code{\link[=makeSummarizedExperimentFromBiom]{makeSummarizedExperimentFromBiom}}
#' \code{\link[=makeTreeSummarizedExperimentFromDADA2]{makeTreeSummarizedExperimentFromDADA2}}
#' \code{\link[=loadFromQIIME2]{loadFromQIIME2}}
#' \code{\link[=loadFromMothur]{loadFromMothur}}
#'
#' @export
#' @author Leo Lahti and Tuomas Borman. Contact: \url{microbiome.github.io}
#' 
#' @references
#' Beghini F, McIver LJ, Blanco-Míguez A, Dubois L, Asnicar F, Maharjan S, Mailyan A, 
#' Manghi P, Scholz M, Thomas AM, Valles-Colomer M, Weingart G, Zhang Y, Zolfo M, 
#' Huttenhower C, Franzosa EA, & Segata N (2021) Integrating taxonomic, functional, 
#' and strain-level profiling of diverse microbial communities with bioBakery 3.
#' Elife 10:e65088. doi: 10.7554/eLife.65088
#'
#' @examples
#' # (Data is from tutorial
#' # https://github.com/biobakery/biobakery/wiki/metaphlan3#merge-outputs)
#' 
#' # File path
#' file_path <- system.file("extdata", "merged_abundance_table.txt", package = "mia")
#' # Import data
#' tse <- loadFromMetaphlan(file_path)
#' # Data at the lowest rank
#' tse
#' # Data at higher rank is stored in altExp
#' altExps(tse)
#' # Higher rank data is in SE format, for example, Phylum rank
#' altExp(tse, "Phylum")
#' 
NULL

loadFromMetaphlan <- function(file, sample_meta = NULL, phy_tree = NULL, ...){
    ################################ Input check ################################
    if(!.is_non_empty_string(file)){
        stop("'file' must be a single character value.",
             call. = FALSE)
    }
    if (!file.exists(file)) {
        stop(file, " does not exist", call. = FALSE)
    }
    if(!is.null(sample_meta) && !.is_non_empty_string(sample_meta)){
        stop("'sample_meta' must be a single character value or NULL.",
             call. = FALSE)
    }
    if(!is.null(phy_tree) && !.is_non_empty_string(phy_tree)){
        stop("'phy_tree' must be a single character value or NULL.",
             call. = FALSE)
    }
    ############################## Input check end #############################
    # Read metaphlan data
    data <- .read_metaphlan(file, ...)
    # Parse data into separate tables, which include data at certain taxonomy rank
    tables <- .parse_metaphlan(data, ...)
    # Create multiple SE objects at different rank from the data
    se_objects <- lapply(tables, .create_se_from_metaphlan, ...)
    
    # Get the object with lowest rank
    tse <- se_objects[[ length(se_objects) ]]
    # Convert it to TreeSE so that it has altExp
    tse <- as(tse, "TreeSummarizedExperiment")
    # Remove it, so that it is not added multiple times
    se_objects[[ length(se_objects) ]] <- NULL
    # Add rest of the objects to altExp
    if( length(se_objects) > 0 ){
        for( rank in names(se_objects) ){
            # Add SEs to altExp of tse, give name according to rank
            altExp(tse, rank) <- se_objects[[rank]]
        }
    }
    
    # Load sample meta data if it is provided, otherwise initialize empty table
    if (!is.null(sample_meta)) {
        coldata <- read.table(file = sample_meta, header = TRUE, sep = "\t")
        colData(tse) <- coldata
    }
    
    # Load tree if it is provided
    if (!is.null(phy_tree)) {
        tree <- ape::read.tree(phy_tree)
        rowTree(tse) <- tree
    } 
    
    return(tse)
}

################################ HELP FUNCTIONS ################################

# Read Metaphlan file, catch error if it occurs
.read_metaphlan <- function(file, ...){
    # Read the table. Catch error and give more informative message
    table <- tryCatch(
        {
            read.table(file, header = TRUE, comment.char = "#")
        },
        error = function(condition){
            stop("Error while reading ", file,
                 "\nPlease check that the file is in merged Metaphlan file format.",
                 call. = FALSE)
        }
    )
    # Check that file is in right format
    if( .check_metaphlan(table) ){
        stop("Error while reading ", file,
             "\nPlease check that the file is in merged Metaphlan file format.",
             call. = FALSE)
    }
    return(table)
}

# Check that metaphlan file contains correct information
.check_metaphlan <- function(data){
    # Get rowdata columns
    rowdata_columns <- data[ , 1:2]
    # Get columns that go to assay
    assay_columns <- data[ , 3:ncol(data)]
    # Initialize result 
    result <- TRUE
    
    # Check rowdata column names that they contain right information, and check that 
    # rest of the columns represents abundances in samples.
    # If these requirements are met, give FALSE. Otherwise, give TRUE.
    if( any(colnames(rowdata_columns) %in% "clade_name") && 
        any(grepl("id", colnames(rowdata_columns))) && 
        is.numeric(unlist(assay_columns)) ){
        result <- FALSE
    }
    return(result)
}

# Get metaphlan table as input and return multiple tables which each include data at
# certain taxonomy rank
.parse_metaphlan <- function(table, ...){
    # Get the lowest level of each row
    levels <- lapply(table[["clade_name"]], FUN = .get_lowest_taxonomic_level)
    # Convert list to vector
    levels <- unlist(levels)
    # Split table so that each individual table contains information only
    # at specific rank
    tables <- split(table, levels)
    # Different ranks in order
    ranks <- c("Domain", "Kingdom", "Phylum", "Order", "Family", "Genus", "Species")
    # Get the order
    indices <- match(ranks, names(tables))
    # Remove NAs which occurs if rank is not included
    indices <- indices[!is.na(indices)]
    # Order tables 
    tables <- tables[indices]
    return(tables)
}

# Get the lowest level of the string that contains multiple taxonomic levels with prefixes
# Output is single character that specifies the rank, e.g, "s" == "Species"
.get_lowest_taxonomic_level <- function(string){
    # Get indices that specify location of rank prefixes 
    levels <- gregexpr("([kpcofgs]+)__", string)[[1]]
    # Get the location of lowest rank
    lowest_level_ind <- levels[length(levels)]
    # Get the lowest rank that was found
    lowest_level <- substr(string, start = lowest_level_ind, stop = lowest_level_ind)
    
    # List all ranks and what prefix they correspond
    ranks <- c(Domain = "d", Kingdom = "k", Phylum = "p", Order = "o", 
               Family = "f", Genus = "g", Species = "s")
    # Convert prefix into full rank name
    lowest_level <- names(ranks[ match(lowest_level, ranks) ])
    return(lowest_level)
}

# Create SE object that include rowdata and assay, from the metaphlan table
.create_se_from_metaphlan <- function(table, abund_values = "counts", ...){
    # Check abund_values
    if( !.is_non_empty_character(abund_values) ){
        stop("'abund_values' must be a non-empty character value.",
             call. = FALSE)
    }
    # Get those columns that belong to rowData
    rowdata <- table[, 1:2, drop = FALSE]
    # Get those columns that belong to assay
    assay <- table[, 3:ncol(table), drop = FALSE]
    # Parse taxonomic levels
    taxonomy <- .parse_taxonomy(rowdata[ , 1, drop = FALSE], sep = "\\|", column_name = "clade_name", ...)
    # Add parsed taxonomy level information to rowdata
    rowdata <- cbind(taxonomy, rowdata)
    
    # Create assays list and add assay with specific name
    assays <- S4Vectors::SimpleList()
    assays[[abund_values]] <- assay
    
    # Create SE
    se <- SummarizedExperiment(assays = assays,
                                rowData = rowdata)
    # Add taxonomy labels
    rownames(se) <- getTaxonomyLabels(se)
    return(se)
}
