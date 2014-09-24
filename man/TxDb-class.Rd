\name{TxDb-class}

\alias{TxDb-class}
\alias{class:TxDb}
\alias{TxDb}

\alias{seqinfo,TxDb-method}
\alias{seqinfo<-,TxDb-method}
\alias{isActiveSeq}
\alias{isActiveSeq<-}
\alias{isActiveSeq,TxDb-method}
\alias{isActiveSeq<-,TxDb-method}

% coercion
\alias{as.list,TxDb-method}

\title{TxDb objects}

\description{
  The TxDb class is a container for storing transcript annotations.

  See \code{?\link{FeatureDb}} for a more generic container for storing
  genomic locations of an arbitrary type of genomic features.

  See \code{?\link{makeTranscriptDbFromUCSC}} and
  \code{?\link{makeTranscriptDbFromBiomart}} for convenient ways to
  make TxDb objects from UCSC or BioMart online resources.

  See \code{?\link{makeTranscriptDbFromGFF}} for making a TxDb
  object from annotations available as a GFF3 or GTF file.
}

\section{Methods}{
  In the code snippets below, \code{x} is a TxDb object.

  \describe{
    \item{}{
      \code{metadata(x)}:
      Return \code{x}'s metadata in a data frame.
    }
    \item{}{
      \code{seqinfo(x)}, \code{seqinfo(x) <- value}:
      Get or set the information about the underlying sequences.
      Note that, for now, the setter only supports replacement of the
      sequence names, i.e., except for their sequence names (accessed with
      \code{seqnames(value)} and \code{seqnames(seqinfo(x))}, respectively),
      \link[GenomeInfoDb]{Seqinfo} objects \code{value} (supplied) and
      \code{seqinfo(x)} (current) must be identical.
    }
    \item{}{
      \code{isActiveSeq(x)}:
      Return the currently active sequences for this txdb object as a
      named logical vector.  Only active sequences will be tapped when
      using the supplied accessor methods.  Inactive sequences will be
      ignored.  By default, all available sequences will be active.
    } 
    \item{}{
      \code{isActiveSeq(x) <- value}:
      Allows the user to change which sequences will be actively
      accessed by the accessor methods by altering the contents of this
      named logical vector.
    }
    \item{}{
      \code{seqlevelsStyle(x)}, \code{seqlevelsStyle(x) <- value}:
      Get or set the seqname style for \code{x}.
      See the \link[GenomeInfoDb]{seqlevelsStyle} generic getter and setter
      in the \pkg{GenomeInfoDb} package for more information.
    }
    \item{}{
      \code{as.list(x)}:
      Dumps the entire db into a list of data frames \code{txdump} that can
      be used in \code{do.call(makeTranscriptDb, txdump)} to make the db
      again with no loss of information.
      Note that the transcripts are dumped in the same order in all the
      data frames.
    }
  }
}

\author{H. Pages, Marc Carlson}

\seealso{
  \itemize{
    \item The \link{FeatureDb} class for storing
          genomic locations of an arbitrary type of genomic features.
    \item \code{\link{makeTranscriptDbFromUCSC}} and
          \code{\link{makeTranscriptDbFromBiomart}} for convenient ways to
          make TxDb objects from UCSC or BioMart online resources.
    \item \code{\link{makeTranscriptDbFromGFF}} for making a TxDb
          object from annotations available as a GFF3 or GTF file.
    \item \code{\link{saveDb}} and \code{\link{loadDb}} for
          saving and loading the database content of a TxDb object.
    \item \code{\link{transcripts}}, \code{\link{transcriptsBy}},
          and \code{\link{transcriptsByOverlaps}},
          for how to extract genomic features from a TxDb object.
    \item \link[GenomicFeatures]{select-methods} for how to use the
          simple "select" interface to extract information from a
          TxDb object.
    \item The \link[GenomeInfoDb]{Seqinfo} class in the \pkg{GenomeInfoDb}
          package.
  }
}

\examples{
txdb_file <- system.file("extdata", "Biomart_Ensembl_sample.sqlite",
                         package="GenomicFeatures")
txdb <- loadDb(txdb_file)
txdb

## Use of seqinfo
seqlevelsStyle(txdb)
seqinfo(txdb)
seqlevels(txdb)
seqlengths(txdb)  # shortcut for 'seqlengths(seqinfo(txdb))'
isCircular(txdb)  # shortcut for 'isCircular(seqinfo(txdb))'
names(which(isCircular(txdb)))

## Can set txdb so that only chr1 and chr2 are used by using the seqlevels
seqlevels(txdb, force=TRUE) <- c("1", "2")
## And then you can restore the default seqlevels
txdb <- restoreSeqlevels(txdb)


## Use of as.list
txdump <- as.list(txdb)
txdump
txdb1 <- do.call(makeTranscriptDb, txdump)
stopifnot(identical(as.list(txdb1), txdump))
}

\keyword{methods}
\keyword{classes}