\name{transcripts}

\alias{transcripts}
\alias{transcripts,TxDb-method}
\alias{exons}
\alias{exons,TxDb-method}
\alias{cds}
\alias{cds,TxDb-method}
\alias{genes}
\alias{genes,TxDb-method}
\alias{promoters}
\alias{terminators}
\alias{promoters,TxDb-method}
\alias{terminators,TxDb-method}

\title{
  Extract genomic features from a TxDb-like object
}

\description{
  Generic functions to extract genomic features from a TxDb-like object.
  This page documents the methods for \link{TxDb} objects only.
}

\usage{
transcripts(x, ...)
\S4method{transcripts}{TxDb}(x, columns=c("tx_id", "tx_name"), filter=NULL, use.names=FALSE)

exons(x, ...)
\S4method{exons}{TxDb}(x, columns="exon_id", filter=NULL, use.names=FALSE)

cds(x, ...)
\S4method{cds}{TxDb}(x, columns="cds_id", filter=NULL, use.names=FALSE)

genes(x, ...)
\S4method{genes}{TxDb}(x, columns="gene_id", filter=NULL, single.strand.genes.only=TRUE)

\S4method{promoters}{TxDb}(x, upstream=2000, downstream=200, use.names=TRUE, ...)
\S4method{terminators}{TxDb}(x, upstream=2000, downstream=200, use.names=TRUE, ...)
}

\arguments{
  \item{x}{
    A \link{TxDb} object.
  }
  \item{...}{
    For the \code{transcripts()}, \code{exons()}, \code{cds()}, and
    \code{genes()} generic functions: arguments to be passed to methods.

    For the \code{promoters()} and \code{terminators()} methods for
    \link{TxDb} objects: arguments to be passed to the internal call
    to \code{transcripts()}.
  }
  \item{columns}{
    Columns to include in the output.
    Must be \code{NULL} or a character vector as given by the
    \code{columns} method. With the following restrictions:
    \itemize{
      \item \code{"TXCHROM"} and \code{"TXSTRAND"} are not allowed
            for \code{transcripts()}.
      \item \code{"EXONCHROM"} and \code{"EXONSTRAND"} are not allowed
            for \code{exons()}.
      \item \code{"CDSCHROM"} and \code{"CDSSTRAND"} are not allowed
            for \code{cds()}.
    }
    If the vector is named, those names are used for the corresponding
    column in the element metadata of the returned object.
  }
  \item{filter}{
    Either \code{NULL} or a named list of vectors to be used to
    restrict the output. Valid names for this list are:
    \code{"gene_id"},
    \code{"tx_id"}, \code{"tx_name"},
    \code{"tx_chrom"}, \code{"tx_strand"},
    \code{"exon_id"}, \code{"exon_name"},
    \code{"exon_chrom"}, \code{"exon_strand"},
    \code{"cds_id"}, \code{"cds_name"},
    \code{"cds_chrom"}, \code{"cds_strand"} and \code{"exon_rank"}.
  }
  \item{use.names}{
    \code{TRUE} or \code{FALSE}. If \code{TRUE}, the feature names are
    set as the names of the returned object, with NAs being replaced with
    empty strings.
  }
  \item{single.strand.genes.only}{
    \code{TRUE} or \code{FALSE}.
    If \code{TRUE} (the default), then genes are returned in a
    \link[GenomicRanges]{GRanges} object and those genes that cannot be
    represented by a single genomic range (because they have exons located
    on both strands of the same reference sequence or on more than one
    reference sequence) are dropped with a message.

    If \code{FALSE}, then all the genes are returned in a
    \link[GenomicRanges]{GRangesList} object with the columns specified
    thru the \code{columns} argument set as \emph{top level} metadata
    columns. (Please keep in mind that the \emph{top level} metadata
    columns of a \link[GenomicRanges]{GRangesList} object are not displayed
    by the \code{show()} method.)
  }
  \item{upstream, downstream}{
    For \code{promoters()}: Single integer values indicating the number
    of bases upstream and downstream from the TSS (transcription start
    sites).

    For \code{terminators()}: Single integer values indicating the number
    of bases upstream and downstream from the TES (transcription end
    sites).

    For additional details see
    \code{?GenomicRanges::\link[GenomicRanges]{promoters}} in the
    \pkg{GenomicRanges} package.
  }
}

\details{
  These are the main functions for extracting features from a
  \link{TxDb}-like object. Note that \code{cds()} extracts the
  bulk \emph{CDS parts} stored in \code{x}, that is, the CDS regions
  associated with exons. It is often more useful to extract them grouped
  by transcript with \code{\link{cdsBy}()}.

  To restrict the output based on interval information, use the
  \code{\link{transcriptsByOverlaps}()}, \code{\link{exonsByOverlaps}()},
  or \code{\link{cdsByOverlaps}()} function.

  The \code{promoters()} and \code{terminators()} functions compute
  user-defined promoter or terminator regions for the transcripts
  in a \link{TxDb}-like object. The returned object is a
  \link[GenomicRanges]{GRanges} with one range per transcript
  in the \link{TxDb}-like object.
  Each range represents the promoter or terminator region associated
  with a transcript, that is, the region around the TSS
  (transcription start site) or TES (transcription end site) the
  span of which is defined by \code{upstream} and \code{downstream}.

  For additional details on how the promoter and terminator ranges
  are computed and the handling of \code{+} and \code{-} strands see
  \code{?GenomicRanges::\link[GenomicRanges]{promoters}} in the
  \pkg{GenomicRanges} package.
}

\value{
  A \link[GenomicRanges]{GRanges} object. The only exception being
  when \code{genes()} is used with \code{single.strand.genes.only=FALSE},
  in which case a \link[GenomicRanges]{GRangesList} object is returned.
}

\author{
  M. Carlson, P. Aboyoun and H. Pagès
}

\seealso{
  \itemize{
    \item \code{\link{transcriptsBy}} and \code{\link{transcriptsByOverlaps}}
          for more ways to extract genomic features
          from a \link{TxDb}-like object.

    \item \code{\link{transcriptLengths}} for extracting the transcript
          lengths (and other metrics) from a \link{TxDb} object.

    \item \code{\link{exonicParts}} and \code{\link{intronicParts}} for
          extracting non-overlapping exonic or intronic parts from a
          TxDb-like object.

    \item \code{\link{extendExonsIntoIntrons}} for extending exons
          into their adjacent introns.

    \item \code{\link{extractTranscriptSeqs}} for extracting transcript
          (or CDS) sequences from reference sequences.

    \item \code{\link{getPromoterSeq}} for extracting gene promoter or
          terminator sequences.

    \item \code{\link{coverageByTranscript}} for computing coverage by
          transcript (or CDS) of a set of ranges.

    \item \link[GenomicFeatures]{select-methods} for how to use the
          simple "select" interface to extract information from a
          \link{TxDb} object.

    \item \code{\link{microRNAs}} and \code{\link{tRNAs}} for extracting
          microRNA or tRNA genomic ranges from a \link{TxDb} object.

    \item \code{\link{id2name}} for mapping \link{TxDb} internal ids
          to external names for a given feature type.

    \item The \link{TxDb} class.
  }
}

\examples{
txdb_file <- system.file("extdata", "hg19_knownGene_sample.sqlite",
                         package="GenomicFeatures")
txdb <- loadDb(txdb_file)

## ---------------------------------------------------------------------
## transcripts()
## ---------------------------------------------------------------------

tx1 <- transcripts(txdb)
tx1

transcripts(txdb, use.names=TRUE)
transcripts(txdb, columns=NULL, use.names=TRUE)

filter <- list(tx_chrom = c("chr3", "chr5"), tx_strand = "+")
tx2 <- transcripts(txdb, filter=filter)
tx2

## Sanity checks:
stopifnot(
  identical(mcols(tx1)$tx_id, seq_along(tx1)),
  identical(tx2, tx1[seqnames(tx1) == "chr3" & strand(tx1) == "+"])
)

## ---------------------------------------------------------------------
## exons()
## ---------------------------------------------------------------------

exons(txdb, columns=c("EXONID", "TXNAME"),
            filter=list(exon_id=1))
exons(txdb, columns=c("EXONID", "TXNAME"),
            filter=list(tx_name="uc009vip.1"))

## ---------------------------------------------------------------------
## genes()
## ---------------------------------------------------------------------

genes(txdb)  # a GRanges object
cols <- c("tx_id", "tx_chrom", "tx_strand",
          "exon_id", "exon_chrom", "exon_strand")
## By default, genes are returned in a GRanges object and those that
## cannot be represented by a single genomic range (because they have
## exons located on both strands of the same reference sequence or on
## more than one reference sequence) are dropped with a message:
single_strand_genes <- genes(txdb, columns=cols)

## Because we've returned single strand genes only, the "tx_chrom"
## and "exon_chrom" metadata columns are guaranteed to match
## 'seqnames(single_strand_genes)':
stopifnot(identical(as.character(seqnames(single_strand_genes)),
                    as.character(mcols(single_strand_genes)$tx_chrom)))
stopifnot(identical(as.character(seqnames(single_strand_genes)),
                    as.character(mcols(single_strand_genes)$exon_chrom)))

## and also the "tx_strand" and "exon_strand" metadata columns are
## guaranteed to match 'strand(single_strand_genes)':
stopifnot(identical(as.character(strand(single_strand_genes)),
                    as.character(mcols(single_strand_genes)$tx_strand)))
stopifnot(identical(as.character(strand(single_strand_genes)),
                    as.character(mcols(single_strand_genes)$exon_strand)))

all_genes <- genes(txdb, columns=cols, single.strand.genes.only=FALSE)
all_genes  # a GRangesList object
multiple_strand_genes <- all_genes[elementNROWS(all_genes) >= 2]
multiple_strand_genes
mcols(multiple_strand_genes)

## ---------------------------------------------------------------------
## promoters() and terminators()
## ---------------------------------------------------------------------

## This:
promoters(txdb, upstream=100, downstream=50)
## is equivalent to:
tx <- transcripts(txdb, use.names=TRUE)
promoters(tx, upstream=100, downstream=50)

## And this:
terminators(txdb, upstream=100, downstream=50)
## is equivalent to:
terminators(tx, upstream=100, downstream=50)

## Extra arguments are passed to transcripts(). So this:
columns <- c("tx_name", "gene_id")
promoters(txdb, upstream=100, downstream=50, columns=columns)
## is equivalent to:
promoters(transcripts(txdb, columns=columns, use.names=TRUE),
          upstream=100, downstream=50)
}

\keyword{methods}
