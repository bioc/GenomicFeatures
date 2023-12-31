\name{mapToTranscripts}
\alias{coordinate-mapping}

\alias{mapToTranscripts}
\alias{mapToTranscripts,GenomicRanges,GenomicRanges-method}
\alias{mapToTranscripts,GenomicRanges,GRangesList-method}
\alias{mapToTranscripts,ANY,TxDb-method}
\alias{pmapToTranscripts}
\alias{pmapToTranscripts,GenomicRanges,GenomicRanges-method}
\alias{pmapToTranscripts,GenomicRanges,GRangesList-method}
\alias{pmapToTranscripts,GRangesList,GRangesList-method}

\alias{mapFromTranscripts}
\alias{mapFromTranscripts,GenomicRanges,GenomicRanges-method}
\alias{mapFromTranscripts,GenomicRanges,GRangesList-method}
\alias{pmapFromTranscripts}
\alias{pmapFromTranscripts,IntegerRanges,GenomicRanges-method}
\alias{pmapFromTranscripts,IntegerRanges,GRangesList-method}
\alias{pmapFromTranscripts,GenomicRanges,GenomicRanges-method}
\alias{pmapFromTranscripts,GenomicRanges,GRangesList-method}

\title{Map range coordinates between transcripts and genome space}

\description{
  Map range coordinates between features in the transcriptome and
  genome (reference) space.

  See \code{?\link[GenomicAlignments]{mapToAlignments}} in the
  \pkg{GenomicAlignments} package for mapping coordinates between
  reads (local) and genome (reference) space using a CIGAR alignment.
}

\usage{
## mapping to transcripts
\S4method{mapToTranscripts}{GenomicRanges,GenomicRanges}(x, transcripts,
          ignore.strand = FALSE)
\S4method{mapToTranscripts}{GenomicRanges,GRangesList}(x, transcripts,
          ignore.strand = FALSE, intronJunctions=FALSE)
\S4method{mapToTranscripts}{ANY,TxDb}(x, transcripts, ignore.strand = FALSE,
          extractor.fun = GenomicFeatures::transcripts, ...)
\S4method{pmapToTranscripts}{GenomicRanges,GRangesList}(x, transcripts,
          ignore.strand = FALSE)

## mapping from transcripts
\S4method{mapFromTranscripts}{GenomicRanges,GRangesList}(x, transcripts,
          ignore.strand = FALSE)
\S4method{pmapFromTranscripts}{GenomicRanges,GRangesList}(x, transcripts,
          ignore.strand = FALSE)
\S4method{pmapFromTranscripts}{IntegerRanges,GRangesList}(x, transcripts)
}

\arguments{
  \item{x}{
    \link[GenomicRanges]{GenomicRanges} object of positions to be mapped.
    The seqnames of \code{x} are used in \code{mapFromTranscripts}, i.e.,
    when mapping from transcripts to the genome. In the case of
    \code{pmapFromTranscripts}, \code{x} can be an
    \link[IRanges]{IntegerRanges} object.
  }
  \item{transcripts}{
    A named \link[GenomicRanges]{GenomicRanges} or
    \link[GenomicRanges]{GRangesList} object used to map between \code{x}
    and the result. The ranges can be any feature in the transcriptome
    extracted from a \code{TxDb} (e.g., introns, exons, CDS parts).
    See ?\code{transcripts} and ?\code{transcriptsBy} for a list of
    extractor functions.

    The \code{transcripts} object must have names. When mapping from
    transcripts to the genome, they are used to determine mapping pairs; in
    the reverse direction they become the seqlevels of the output object.
  }
  \item{ignore.strand}{
    When \code{ignore.strand} is TRUE, strand is ignored in overlaps operations
    (i.e., all strands are considered "+") and the strand in the output is '*'.

    When \code{ignore.strand} is FALSE strand in the output is taken from the
    \code{transcripts} argument. When \code{transcripts} is a
    \code{GRangesList}, all inner list elements of a common list element must
    have the same strand or an error is thrown.

    Mapped position is computed by counting from the transcription start site
    (TSS) and is not affected by the value of \code{ignore.strand}.
  }
  \item{intronJunctions}{
    Logical to indicate if intronic ranges in \code{x} should be reported.

    This argument is only supported in \code{mapToTranscripts} when
    \code{transcripts} is a GRangesList.  When \code{transcripts} is a
    GRangesList, individual ranges can be thought of as exons and the spaces
    between the ranges as introns. 
   
    When \code{intronJunctions=TRUE}, ranges that fall completely "within" an
    intron are reported as a zero-width range (start and end are taken
    from the ranges they fall between). A metadata column called "intronic" is
    returned with the GRanges and marked as \code{TRUE} for these ranges. By
    default, \code{intronJunctions=FALSE} and these ranges are not mapped.
    
    Ranges that have either the start or end in an intron are considered "non
    hits" and are never mapped.  Ranges that span introns are always mapped.
    Neither of these range types are controlled by the \code{intronJunctions}
    argument.
  }
  \item{extractor.fun}{
    Function to extract genomic features from a \code{TxDb} object.

    This argument is only applicable to \code{mapToTranscripts} when
    \code{transcripts} is a \code{TxDb} object. The \code{extractor} should
    be the name of a function (not a character()) described on the
    \code{?transcripts}, \code{?transcriptsBy}, or \code{?microRNAs} man page.

    Valid \code{extractor} functions:
    \itemize{
      \item{transcripts}  ## default
      \item{exons}
      \item{cds}
      \item{genes}
      \item{promoters}
      \item{exonicParts}
      \item{intronicParts}
      \item{transcriptsBy}
      \item{exonsBy}
      \item{cdsBy}
      \item{intronsByTranscript}
      \item{fiveUTRsByTranscript}
      \item{threeUTRsByTranscript}
      \item{microRNAs}
      \item{tRNAs}
    }
  }
  \item{\dots}{
    Additional arguments passed to \code{extractor.fun} functions.
  }
}

\details{
  In GenomicFeatures >= 1.21.10, the default for \code{ignore.strand} was
  changed to \code{FALSE} for consistency with other methods in the
  \pkg{GenomicRanges} and \pkg{GenomicAlignments} packages. Additionally,
  the mapped position is computed from the TSS and does not depend on the
  \code{ignore.strand} argument.
  See the section on \code{ignore.strand} for details.

  \itemize{
    \item{\code{mapToTranscripts}, \code{pmapToTranscripts}}{
      The genomic range in \code{x} is mapped to the local position in the
      \code{transcripts} ranges. A successful mapping occurs when \code{x}
      is completely within the \code{transcripts} range, equivalent to:
      \preformatted{
      findOverlaps(..., type="within")
      }
      Transcriptome-based coordinates start counting at 1 at the beginning
      of the \code{transcripts} range and return positions where \code{x}
      was aligned. The seqlevels of the return object are taken from the
      \code{transcripts} object and should be transcript names. In this
      direction, mapping is attempted between all elements of \code{x} and
      all elements of \code{transcripts}.

      \code{mapToTranscripts} uses \code{findOverlaps} to map ranges in
      \code{x} to ranges in \code{transcripts}. This method does not return
      unmapped ranges.

      \code{pmapToTranscripts} maps the i-th range in \code{x} to the
      i-th range in \code{transcripts}. Recycling is supported for both
      \code{x} and \code{transcripts} when either is length == 1L; otherwise
      the lengths must match. Ranges in \code{x} that do not map (out of bounds
      or strand mismatch) are returned as zero-width ranges starting at 0.
      These ranges are given the seqname of "UNMAPPED".
    }
    \item{\code{mapFromTranscripts}, \code{pmapFromTranscripts}}{
      The transcript-based position in \code{x} is mapped to genomic coordinates
      using the ranges in \code{transcripts}. A successful mapping occurs when
      the following is TRUE:
      \preformatted{
      width(transcripts) >= start(x) + width(x)
      }
      \code{x} is aligned to \code{transcripts} by moving in \code{start(x)}
      positions in from the beginning of the \code{transcripts} range.  The
      seqlevels of the return object are chromosome names.

      \code{mapFromTranscripts} uses the seqname of \code{x} and the names
      of \code{transcripts} to determine mapping pairs (vs attempting to match
      all possible pairs). Name matching is motivated by use cases such as
      differentially expressed regions where the expressed regions in \code{x}
      would only be related to a subset of regions in \code{transcripts}.
      This method does not return unmapped ranges.

      \code{pmapFromTranscripts} maps the i-th range in \code{x} to the i-th
      range in \code{transcripts} and therefore does not use name matching.
      Recycling is supported in \code{pmapFromTranscripts} when either
      \code{x} or \code{transcripts} is length == 1L; otherwise the lengths
      must match. Ranges in \code{x} that do not map (out of bounds or strand
      mismatch) are returned as zero-width ranges starting at 0. These ranges
      are given the seqname of "UNMAPPED".
    }
  }
}

\value{

  \code{pmapToTranscripts} returns a \code{GRanges} the same length as
  \code{x}.

  \code{pmapFromTranscripts} returns a \code{GRanges} when \code{transcripts}
  is a \code{GRanges} and a \code{GRangesList} when \code{transcripts}
  is a \code{GRangesList}. In both cases the return object is the same
  length as \code{x}. The rational for returning the \code{GRangesList} is
  to preserve exon structure; ranges in a list element that are not overlapped
  by \code{x} are returned as a zero-width range. The \code{GRangesList}
  return object will have no seqlevels called "UNMAPPED"; those will only
  occur when a \code{GRanges} is returned.

  \code{mapToTranscripts} and \code{mapFromTranscripts} return \code{GRanges}
  objects that vary in length similar to a \code{Hits} object. The result
  contains mapped records only; strand mismatch and out of bound ranges are
  not returned. \code{xHits} and \code{transcriptsHits} metadata columns
  (similar to the \code{queryHits} and \code{subjectHits} of a \code{Hits}
  object) indicate elements of \code{x} and \code{transcripts} used in
  the mapping.

  When \code{intronJunctions} is TRUE, \code{mapToTranscripts} returns an
  extra metdata column named \code{intronic} to identify the intron ranges.

  When mapping to transcript coordinates, seqlevels of the output are the names
  on the \code{transcripts} object and most often these will be transcript
  names. When mapping to the genome, seqlevels of the output are the seqlevels
  of \code{transcripts} which are usually chromosome names.
}

\seealso{
  \itemize{
    \item \code{?\link[GenomicAlignments]{mapToAlignments}} in the
    \pkg{GenomicAlignments} package for methods mapping between
    reads and genome space using a CIGAR alignment.
  }
}

\author{V. Obenchain, M. Lawrence and H. Pagès}

\examples{
## ---------------------------------------------------------------------
## A. Basic Use: Conversion between CDS and Exon coordinates and the
##    genome
## ---------------------------------------------------------------------

## Gene "Dgkb" has ENTREZID "217480":
library(org.Mm.eg.db)
Dgkb_geneid <- get("Dgkb", org.Mm.egSYMBOL2EG)

## The gene is on the positive strand, chromosome 12:
library(TxDb.Mmusculus.UCSC.mm10.knownGene)
txdb <- TxDb.Mmusculus.UCSC.mm10.knownGene
tx_by_gene <- transcriptsBy(txdb, by="gene")
Dgkb_transcripts <- tx_by_gene[[Dgkb_geneid]]
Dgkb_transcripts  # all 7 Dgkb transcripts are on chr12, positive strand

## To map coordinates from local CDS or exon space to genome 
## space use mapFromTranscripts().

## When mapping CDS coordinates to genome space the 'transcripts'
## argument is the collection of CDS parts by transcript.
coord <- GRanges("chr12", IRanges(4, width=1))
## Get the names of the transcripts in the gene:
Dgkb_tx_names <- mcols(Dgkb_transcripts)$tx_name
Dgkb_tx_names
## Use these names to isolate the region of interest:
cds_by_tx <- cdsBy(txdb, "tx", use.names=TRUE)
Dgkb_cds_by_tx <- cds_by_tx[intersect(Dgkb_tx_names, names(cds_by_tx))]
## Dgkb CDS parts grouped by transcript (no-CDS transcripts omitted):
Dgkb_cds_by_tx
lengths(Dgkb_cds_by_tx)  # nb of CDS parts per transcript
## A requirement for mapping from transcript space to genome space
## is that seqnames in 'x' match the names in 'transcripts'.
names(Dgkb_cds_by_tx) <- rep(seqnames(coord), length(Dgkb_cds_by_tx))
## There are 6 results, one for each transcript.
mapFromTranscripts(coord, Dgkb_cds_by_tx)

## To map exon coordinates to genome space the 'transcripts'
## argument is the collection of exon regions by transcript.
coord <- GRanges("chr12", IRanges(100, width=1))
ex_by_tx <- exonsBy(txdb, "tx", use.names=TRUE)
Dgkb_ex_by_tx <- ex_by_tx[Dgkb_tx_names]
names(Dgkb_ex_by_tx) <- rep(seqnames(coord), length(Dgkb_ex_by_tx))
## Again the output has 6 results, one for each transcript.
mapFromTranscripts(coord, Dgkb_ex_by_tx)

## To go the reverse direction and map from genome space to
## local CDS or exon space, use mapToTranscripts().

## Genomic position 37981944 maps to CDS position 4:
coord <- GRanges("chr12", IRanges(37981944, width=1))
mapToTranscripts(coord, Dgkb_cds_by_tx)

## Genomic position 37880273 maps to exon position 100:
coord <- GRanges("chr12", IRanges(37880273, width=1))
mapToTranscripts(coord, Dgkb_ex_by_tx)


## The following examples use more than 2GB of memory, which is more
## than what 32-bit Windows can handle:
is_32bit_windows <- .Platform$OS.type == "windows" &&
                    .Platform$r_arch == "i386"
if (!is_32bit_windows) {
## ---------------------------------------------------------------------
## B. Map sequence locations in exons to the genome
## ---------------------------------------------------------------------

## NAGNAG alternative splicing plays an essential role in biological
## processes and represents a highly adaptable system for
## posttranslational regulation of gene function. The majority of
## NAGNAG studies largely focus on messenger RNA. A study by Sun,
## Lin, and Yan (http://www.hindawi.com/journals/bmri/2014/736798/)
## demonstrated that NAGNAG splicing is also operative in large
## intergenic noncoding RNA (lincRNA). One finding of interest was
## that linc-POLR3G-10 exhibited two NAGNAG acceptors located in two
## distinct transcripts: TCONS_00010012 and TCONS_00010010.

## Extract the exon coordinates of TCONS_00010012 and TCONS_00010010:
lincrna <- c("TCONS_00010012", "TCONS_00010010")
library(TxDb.Hsapiens.UCSC.hg19.lincRNAsTranscripts)
txdb <- TxDb.Hsapiens.UCSC.hg19.lincRNAsTranscripts
exons <- exonsBy(txdb, by="tx", use.names=TRUE)[lincrna]
exons

## The two NAGNAG acceptors were identified in the upstream region of
## the fourth and fifth exons located in TCONS_00010012.
## Extract the sequences for transcript TCONS_00010012:
library(BSgenome.Hsapiens.UCSC.hg19)
genome <- BSgenome.Hsapiens.UCSC.hg19
exons_seq <- getSeq(genome, exons[[1]])

## TCONS_00010012 has 4 exons:
exons_seq

## The most common triplet among the lincRNA sequences was CAG. Identify
## the location of this pattern in all exons.
cag_loc <- vmatchPattern("CAG", exons_seq)

## Convert the first occurance of CAG in each exon back to genome
## coordinates.
first_loc <- do.call(c, sapply(cag_loc, "[", 1, simplify=TRUE))
pmapFromTranscripts(first_loc, exons[[1]])

## ---------------------------------------------------------------------
## C. Map dbSNP variants to CDS or cDNA coordinates
## ---------------------------------------------------------------------

## The GIPR gene encodes a G-protein coupled receptor for gastric
## inhibitory polypeptide (GIP). Originally GIP was identified to
## inhibited gastric acid secretion and gastrin release but was later
## demonstrated to stimulate insulin release in the presence of elevated
## glucose.

## In this example 5 SNPs located in the GIPR gene are mapped to cDNA
## coordinates. A list of SNPs in GIPR can be downloaded from dbSNP or
## NCBI.
rsids <- c("rs4803846", "rs139322374", "rs7250736", "rs7250754",
           "rs9749185")

## Extract genomic coordinates with a SNPlocs package.
library(SNPlocs.Hsapiens.dbSNP144.GRCh38)
snps <- snpsById(SNPlocs.Hsapiens.dbSNP144.GRCh38, rsids)

## Gene regions of GIPR can be extracted from a TxDb package of
## compatible build. The TxDb package uses Entrez gene identifiers
## and GIPR is a gene symbol. Let's first lookup its Entrez gene ID.
library(org.Hs.eg.db)
GIPR_geneid <- get("GIPR", org.Hs.egSYMBOL2EG)

## The transcriptsBy() extractor returns a range for each transcript that
## includes the UTR and exon regions (i.e., cDNA).
library(TxDb.Hsapiens.UCSC.hg38.knownGene)
txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene
tx_by_gene <- transcriptsBy(txdb, "gene")
GIPR_transcripts <- tx_by_gene[GIPR_geneid]
GIPR_transcripts  # all 8 GIPR transcripts are on chr19, positive strand

## Before mapping, the chromosome names (seqlevels) in the two
## objects must be harmonized. The style is NCBI for 'snps' and
## UCSC for 'GIPR_transcripts'.
seqlevelsStyle(snps)
seqlevelsStyle(GIPR_transcripts)

## Modify the style (and genome) in 'snps' to match 'GIPR_transcripts'.
seqlevelsStyle(snps) <- seqlevelsStyle(GIPR_transcripts)

## The 'GIPR_transcripts' object is a GRangesList of length 1. This single
## list element contains the cDNA range for 8 different transcripts. To
## map to each transcript individually 'GIPR_transcripts' must be unlisted
## before mapping.

## Map all 5 SNPS to all 8 transcripts:
mapToTranscripts(snps, unlist(GIPR_transcripts))

## Map the first SNP to transcript "ENST00000590918.5" and the second to
## "ENST00000263281.7".
pmapToTranscripts(snps[1:2], unlist(GIPR_transcripts)[1:2])

## The cdsBy() extractor returns CDS parts by gene or by transcript.
## Extract the CDS parts for transcript "ENST00000263281.7".
cds <- cdsBy(txdb, "tx", use.names=TRUE)["ENST00000263281.7"]
cds

## The 'cds' object is a GRangesList of length 1 containing the ranges of
## all CDS parts for single transcript "ENST00000263281.7".

## To map to the concatenated group of ranges leave 'cds' as a GRangesList.
mapToTranscripts(snps, cds)

## Only the second SNP could be mapped. Unlisting the 'cds' object maps
## the SNPs to the individual cds ranges (vs the concatenated range).
mapToTranscripts(snps[2], unlist(cds))

## The location is the same because the SNP hit the first CDS part. If
## the transcript were on the "-" strand the difference in concatenated
## vs non-concatenated position would be more obvious.

## Change strand:
strand(cds) <- strand(snps) <- "-"
mapToTranscripts(snps[2], unlist(cds))
}
}

\keyword{methods}
\keyword{utilities}
