\name{exonicParts}

\alias{tidyTranscripts}
\alias{tidyExons}
\alias{tidyIntrons}
\alias{exonicParts}
\alias{intronicParts}

\title{
  Extract non-overlapping exonic or intronic parts from a TxDb-like object
}

\description{
  \code{exonicParts} and \code{intronicParts} extract the non-overlapping
  (a.k.a. disjoint) exonic or intronic parts from a \link{TxDb}-like object.
}

\usage{
exonicParts(txdb, linked.to.single.gene.only=FALSE)
intronicParts(txdb, linked.to.single.gene.only=FALSE)

## 3 helper functions used internally by exonicParts() and intronicParts():
tidyTranscripts(txdb, drop.geneless=FALSE)
tidyExons(txdb, drop.geneless=FALSE)
tidyIntrons(txdb, drop.geneless=FALSE)
}

\arguments{
  \item{txdb}{
    A \link{TxDb} object, or any \link{TxDb}-like object that supports the
    \code{\link{transcripts}()} and \code{\link{exonsBy}()} extractors
    (e.g. an \link[ensembldb]{EnsDb} object).
  }
  \item{linked.to.single.gene.only}{
    \code{TRUE} or \code{FALSE}.

    If \code{FALSE} (the default), then the disjoint parts are obtained
    by calling \code{\link[IRanges]{disjoin}()} on all the exons (or introns)
    in \code{txdb}, including on exons (or introns) not linked to a gene or
    linked to more than one gene.

    If \code{TRUE}, then the disjoint parts are obtained in 2 steps:
    \enumerate{
      \item call \code{\link[IRanges]{disjoin}()} on the exons (or introns)
            linked to \emph{at least one gene},

      \item then drop the parts linked to more than one gene from
            the set of exonic (or intronic) parts obtained previously.
    }
  }
  \item{drop.geneless}{
    If \code{FALSE} (the default), then all the transcripts (or exons, or
    introns) get extracted from the \link{TxDb} object.

    If \code{TRUE}, then only the transcripts (or exons, or introns) that
    are linked to a gene get extracted from the \link{TxDb} object.

    Note that \code{drop.geneless} also impacts the order in which the
    features are returned:
    \itemize{
      \item Transcripts: If \code{drop.geneless} is \code{FALSE} then
            transcripts are returned in the same order as with
            \code{\link{transcripts}}, which is expected to be by
            internal transcript id (\code{tx_id}).
            Otherwise they are ordered first by gene id (\code{gene_id}),
            then by internal transcript id.
      \item Exons: If \code{drop.geneless} is \code{FALSE} then exons are
            ordered first by internal transcript id (\code{tx_id}),
            then by exon rank (\code{exon_rank}).
            Otherwise they are ordered first by gene id (\code{gene_id}),
            then by internal transcript id, and then by exon rank.
      \item Introns: If \code{drop.geneless} is \code{FALSE} then introns
            are ordered by internal transcript id (\code{tx_id}).
            Otherwise they are ordered first by gene id (\code{gene_id}),
            then by internal transcript id.
    }
  }
}

\value{
  \code{exonicParts} returns a disjoint and strictly sorted
  \link[GenomicRanges]{GRanges} object with 1 range per exonic part
  and with metadata columns \code{tx_id}, \code{tx_name}, \code{gene_id},
  \code{exon_id}, \code{exon_name}, and \code{exon_rank}.
  If \code{linked.to.single.gene.only} was set to \code{TRUE},
  an additional \code{exonic_part} metadata column is added that
  indicates the rank of each exonic part within all the exonic parts
  linked to the same gene.

  \code{intronicParts} returns a disjoint and strictly sorted
  \link[GenomicRanges]{GRanges} object with 1 range per intronic part
  and with metadata columns \code{tx_id}, \code{tx_name}, and \code{gene_id}.
  If \code{linked.to.single.gene.only} was set to \code{TRUE},
  an additional \code{intronic_part} metadata column is added that
  indicates the rank of each intronic part within all the intronic parts
  linked to the same gene.

  \code{tidyTranscripts} returns a \link[GenomicRanges]{GRanges} object
  with 1 range per transcript and with metadata columns \code{tx_id},
  \code{tx_name}, and \code{gene_id}.

  \code{tidyExons} returns a \link[GenomicRanges]{GRanges} object
  with 1 range per exon and with metadata columns \code{tx_id},
  \code{tx_name}, \code{gene_id}, \code{exon_id}, \code{exon_name},
  and \code{exon_rank}.

  \code{tidyIntrons} returns a \link[GenomicRanges]{GRanges} object
  with 1 range per intron and with metadata columns \code{tx_id},
  \code{tx_name}, and \code{gene_id}.
}

\author{Hervé Pagès}

\seealso{
  \itemize{
    \item \code{\link[IRanges]{disjoin}} in the \pkg{IRanges} package.

    \item \code{\link{transcripts}}, \code{\link{transcriptsBy}},
          and \code{\link{transcriptsByOverlaps}}, for extracting
          genomic feature locations from a \link{TxDb}-like object.

    \item \code{\link{transcriptLengths}} for extracting the transcript
          lengths (and other metrics) from a \link{TxDb} object.

    \item \code{\link{extendExonsIntoIntrons}} for extending exons into
          their adjacent introns.

    \item \code{\link{extractTranscriptSeqs}} for extracting transcript
          (or CDS) sequences from chromosome sequences.

    \item \code{\link{coverageByTranscript}} for computing coverage by
          transcript (or CDS) of a set of ranges.

    \item The \link{TxDb} class.
  }
}

\examples{
library(TxDb.Hsapiens.UCSC.hg19.knownGene)
txdb <- TxDb.Hsapiens.UCSC.hg19.knownGene

## ---------------------------------------------------------------------
## exonicParts()
## ---------------------------------------------------------------------

exonic_parts1 <- exonicParts(txdb)
exonic_parts1

## Mapping from exonic parts to genes is many-to-many:
gene_id1 <- mcols(exonic_parts1)$gene_id
gene_id1  # CharacterList object
table(lengths(gene_id1))
## The number of known genes a Human exonic part can be linked to
## varies from 0 to 22!

exonic_parts2 <- exonicParts(txdb, linked.to.single.gene.only=TRUE)
exonic_parts2

## Mapping from exonic parts to genes now is many-to-one:
gene_id2 <- mcols(exonic_parts2)$gene_id
gene_id2[1:20]  # character vector

## Select exonic parts for a given gene:
exonic_parts2[gene_id2 \%in\% "643837"]

## Sanity checks:
stopifnot(isDisjoint(exonic_parts1), isStrictlySorted(exonic_parts1))
stopifnot(isDisjoint(exonic_parts2), isStrictlySorted(exonic_parts2))
stopifnot(all(exonic_parts2 \%within\% reduce(exonic_parts1)))
stopifnot(identical(
    lengths(gene_id1) == 1L,
    exonic_parts1 \%within\% exonic_parts2
))

## ---------------------------------------------------------------------
## intronicParts()
## ---------------------------------------------------------------------

intronic_parts1 <- intronicParts(txdb)
intronic_parts1

## Mapping from intronic parts to genes is many-to-many:
mcols(intronic_parts1)$gene_id
table(lengths(mcols(intronic_parts1)$gene_id))
## A Human intronic part can be linked to 0 to 22 known genes!

intronic_parts2 <- intronicParts(txdb, linked.to.single.gene.only=TRUE)
intronic_parts2

## Mapping from intronic parts to genes now is many-to-one:
class(mcols(intronic_parts2)$gene_id)  # character vector

## Sanity checks:
stopifnot(isDisjoint(intronic_parts1), isStrictlySorted(intronic_parts1))
stopifnot(isDisjoint(intronic_parts2), isStrictlySorted(intronic_parts2))
stopifnot(all(intronic_parts2 \%within\% reduce(intronic_parts1)))
stopifnot(identical(
    lengths(mcols(intronic_parts1)$gene_id) == 1L,
    intronic_parts1 \%within\% intronic_parts2
))

## ---------------------------------------------------------------------
## Helper functions
## ---------------------------------------------------------------------

tidyTranscripts(txdb)                      # Ordered by 'tx_id'.
tidyTranscripts(txdb, drop.geneless=TRUE)  # Ordered first by 'gene_id',
                                           # then by 'tx_id'.

tidyExons(txdb)                            # Ordered first by 'tx_id',
                                           # then by 'exon_rank'.
tidyExons(txdb, drop.geneless=TRUE)        # Ordered first by 'gene_id',
                                           # then by 'tx_id',
                                           # then by 'exon_rank'.

tidyIntrons(txdb)                          # Ordered by 'tx_id'.
tidyIntrons(txdb, drop.geneless=TRUE)      # Ordered first by 'gene_id',
                                           # then by 'tx_id'.
}

\keyword{manip}
