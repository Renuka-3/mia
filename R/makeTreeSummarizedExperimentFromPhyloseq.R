#' Coerce a \code{phyloseq} object to a \code{TreeSummarizedExperiment}
#'
#' \code{makeTreeSummarizedExperimentFromPhyloseq} converts \code{phyloseq}
#' objects into \code{TreeSummarizedExperiment} objects.
#'
#' All data stored in a \code{phyloseq} object is transfered.
#'
#' @param obj a \code{phyloseq} object
#'
#' @return An object of class \code{TreeSummarizedExperiment}
#'
#' @importFrom S4Vectors SimpleList DataFrame make_zero_col_DFrame
#' @importFrom SummarizedExperiment colData colData<-
#'
#' @export
#'
#' @name makeTreeSummarizedExperimentFromPhyloseq
#' @seealso
#' \code{\link[=makeSummarizedExperimentFromBiom]{makeSummarizedExperimentFromBiom}}
#' \code{\link[=makeTreeSummarizedExperimentFromDADA2]{makeTreeSummarizedExperimentFromDADA2}}
#' \code{\link[=loadFromQIIME2]{loadFromQIIME2}}
#' \code{\link[=loadFromMothur]{loadFromMothur}}
#'
#' @examples
#' if (requireNamespace("phyloseq")) {
#'     data(GlobalPatterns, package="phyloseq")
#'     makeTreeSummarizedExperimentFromPhyloseq(GlobalPatterns)
#'     data(enterotype, package="phyloseq")
#'     makeTreeSummarizedExperimentFromPhyloseq(enterotype)
#'     data(esophagus, package="phyloseq")
#'     makeTreeSummarizedExperimentFromPhyloseq(esophagus)
#' }
makeTreeSummarizedExperimentFromPhyloseq <- function(obj) {
    # input check
    .require_package("phyloseq")
    if(!is(obj,"phyloseq")){
        stop("'obj' must be a 'phyloseq' object")
    }
    #
    # Get the assay
    counts <- obj@otu_table@.Data
    # Check the orientation, and transpose if necessary
    if( !obj@otu_table@taxa_are_rows ){
        counts <- t(counts)
    }
    # Create a list of assays
    assays <- SimpleList(counts = counts)
    
    if(!is.null(obj@tax_table@.Data)){
        rowData <- DataFrame(data.frame(obj@tax_table@.Data))
    } else{
        rowData <- S4Vectors::make_zero_col_DFrame(nrow(assays$counts))
        rownames(rowData) <- rownames(assays$counts)
    }
    if(!is.null(obj@sam_data)){
        colData <- DataFrame(data.frame(obj@sam_data))
    } else{
        colData <- S4Vectors::make_zero_col_DFrame(ncol(assays$counts))
        rownames(colData) <- colnames(assays$counts)
    }
    if(!is.null(obj@phy_tree)){
        rowTree <- obj@phy_tree
    } else {
        rowTree <- NULL
    }
    if (!is.null(obj@refseq)) {
        referenceSeq <- obj@refseq
    } else {
        referenceSeq <- NULL
    }
    TreeSummarizedExperiment(assays = assays,
                             rowData = rowData,
                             colData = colData,
                             rowTree = rowTree,
                             referenceSeq = referenceSeq)
}
