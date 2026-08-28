---
layout: single
title: "\"Clustered Index\" Doesn't Mean What You Think It Means (And That's Alright!)"
excerpt: "A book club argument over Kleppmann and Riccomini's DDIA sent me chasing down why \"clustering index\" and \"clustered index\" mean two different physical structures, depending on which database book (or vendor's docs) you're reading."
categories:
  - Blog
tags:
  - clustered-index
  - clustering-index
  - index-organized-table
  - covering-index
  - database-internals
---

![I don't think meme](/images/posts/i-dont-think-meme.gif)

Early this week, during a book club session, I found myself helplessly trying to navigate by heart through the concepts of _**clustered indexes, index-organized tables and covering indexes**_ and getting corrected by fellow readers that were going strictly by Kleppmann and Riccomini's [*Designing Data-Intensive Applications*](https://www.oreilly.com/library/view/designing-data-intensive-applications/9781098119058/) (2nd Edition, 2026). Motivated by my own confusion, I went back to the books I own and the web for clearer definitions.

To cut to the chase, what actually happened is that two database traditions picked the same words (i.e., _"clustering index"_ and _"clustered index"_) for two genuinely different physical structures!

While I'd learned it first from Silberschatz, Korth & Sudarshan's [*Database System Concepts*](https://www.db-book.com/) (currently on 7th Edition, 2021), and a couple of lesser-known books,  Kleppmann and Riccomini's definition matches something else entirely. And it turns out **_their usage is the one that matches the industry's actual database engine implementations!_** Therefore, neither of us were way off during the book discussion or inventing anything, for that matter; we were just each drinking from different wells. 🥲

_This post is the writeup I wish I'd had going into that conversation._ ;-)


## The claim that started it

The definition I knew, in Silberschatz, Korth, and Sudarshan's own words:

> "... a **clustering index** is an index whose search key also defines the sequential order of the file. Clustering indices are also called **primary indices**; the term _primary index_ may appear to denote an index on a primary key, but such indices can in fact be built on any search key. The search key of a clustering index is often the primary key, although that is not  necessarily so. Indices whose search key specifies an order different from the sequential order of the file are called non clustering indices, or secondary indices. The terms "clustered" and "nonclustered" are often used in place of "clustering" and "non clustering."

In other words, they describe a clustering index as one where the heap file itself is ordered according to the index search key.

![silberschatz clustering index concepts](/images/posts/clustering_index_vs_primary_key_index.svg)

But if we check the literature a bit further, Elmasri and Navathe's [Fundamentals of Database Systems](https://www.amazon.com.br/Fundamentals-Database-Systems-Paperback-Elmasri/dp/8131792471) (7th ed, 2016) has an even more specific definition of **Clustering Indexes**:

> _"If file records are physically ordered on a nonkey field — which __does not__ have a distinct value for each record — that field is called the **clustering field** and the data file is called a **clustered file**. We can create a different type of index, called a **clustering index**, to speed up retrieval of all the records that have the same value for the clustering field. This differs from a primary index, which requires that the ordering field of the data file have a **distinct value** for each record. A **clustering index** is also an ordered file with two fields; the first field is of the same type as the clustering field of the data file, and the second field is a disk block pointer. There is one entry in the clustering index for each distinct value of the clustering field, and it contains the value and a pointer to the first block in the data file that has a record with that value for its clustering field._
> 
> _(...)_
> 
> _A clustering index is another example of a nondense (E.N., sparse) index because it has an entry for every distinct value of the indexing field, which is a nonkey by definition and hence has duplicate values rather than a unique value for every record in the file."_

There's a subtle distinction worth flagging here. In Elmasri and Navathe terminology, _if the physical ordering field is the primary key, they normally call the associated index a primary index, not a clustering index._

![navathe clustering index concept](/images/posts/primary_index_vs_clustering_index.svg)


Independently, Oracle has used the term [**Index-Organized Table (IOT)**](https://docs.oracle.com/en/database/oracle/oracle-database/26/cncpt/indexes-and-index-organized-tables.html) since at least Oracle8, though the underlying idea predates the name. In Oracle's own docs, _an IOT is a table with no separate heap file, that is, the data lives directly inside a B-tree, keyed by (typically) the primary key._

DDIA collapses both of these into a single definition:

> "If the actual data (row, document, vertex) is stored directly within the index structure, it is called a **clustered index**. For example, in MySQL’s InnoDB storage engine, the primary key of a table is always a clustered index, and in SQL Server, you can specify one clustered index per table [43]."

<center>
<img src="/images/posts/peter-parker-meme.jpg" alt="alt text" style="width: 30%;">
<br/>
<br/>
</center>

__But that's not an error on their part!__ It's the terminology [MySQL's InnoDB](https://dev.mysql.com/doc/refman/9.7/en/innodb-index-types.html), [SQL Server](https://learn.microsoft.com/en-us/sql/relational-databases/indexes/clustered-and-nonclustered-indexes-described) and [TiDB](https://docs.pingcap.com/tidb/stable/clustered-indexes/), among others, actually use in their own documentation. The "clustered index" in their world *is* what Oracle calls an index-organized table. Same structure, different products/companies, different words.

Markus Winand's [SQL Performance Explained](https://sql-performance-explained.com) (2nd edition, 2025) reconciles IOT and clustered index definitions, as quoted below:

> _"Some databases can indeed use an index as primary table store. The Oracle database calls this concept **index-organized tables (IOT)**, other databases use the term **clustered index**. In this section, both terms are used to either put the emphasis on the table or the index characteristics as needed. An index-organized table is thus a B-tree index without a heap table. This results in two benefits: (1) it saves the space for the heap structure; (2) every access on a clustered index is automatically an index-only scan. Both benefits sound promising but are hardly achievable in practice."_


## Three structures, one collision

Before getting to the confusing part, here's the structure everyone agrees on and the baseline the other two get compared against.

### 1. The baseline: heap file + ordinary secondary index

Rows sit in an unordered heap and a B+-Tree index points into it.

[![Heap file with secondary index](/images/posts/01-heap-plus-secondary-index.svg)](/images/posts/01-heap-plus-secondary-index.svg)

### 2. "Clustering index": the academic vernacular (Silberschatz's/Navathe's)

_The heap file is still there, but it's been physically sorted to match the index key._ Because order matches, the index doesn't even need an entry for every row, one entry per disk block is enough (i.e., it can be a sparse index).

[![Clustering index over a sorted heap](/images/posts/02-clustering-index-silberschatz.svg)](/images/posts/02-clustering-index-silberschatz.svg)

The important detail: this is a *maintained property*, not a structural guarantee. New inserts can land out of order until the next reorganize.  `OPTIMIZE TABLE` in [MySQL's MyISAM](https://dev.mysql.com/doc/refman/8.0/en/optimize-table.html) engine, or `CLUSTER` in [PostgreSQL](https://www.postgresql.org/docs/current/sql-cluster.html) are both real-world instances of this exact concept.

__Db2__ goes a step further than MySQL and PostgreSQL: it names this concept directly. Its own [documentation](https://www.ibm.com/docs/en/db2/11.5.x?topic=indexes-clustered-non-clustered) describes a clustering index as one that determines how rows are physically ordered in a table space; a genuinely separate object from the table, exactly like Silberschatz's model. [Db2](https://www.ibm.com/docs/en/db2-for-zos/12.0.0?topic=gia-clustering-indexes) even tracks a cluster ratio to measure how well-sorted the heap currently is, and recommends a `REORG` when it drifts.

One caveat: Db2's clustering index is still a dense (B-tree) index, with one entry per row. Silberschatz's definition allows the index itself to go sparse once ordering is guaranteed, but Db2 doesn't take that shortcut. So it's a real match on the heap-file question, just not on the sparse-index detail.

### 3. "Clustered index" / index-organized table: the engineering vernacular (InnoDB, SQL Server, Oracle IOT, TiDB)

_No heap file exists._ The B-tree's leaf nodes directly hold the row data.

[![Clustered index with no separate heap](/images/posts/03-clustered-index-iot.svg)](/images/posts/03-clustered-index-iot.svg)


Here the sort order isn't something you maintain. It's structurally impossible to violate, because there's nothing to fall out of sync. The row *is* the leaf.

One more consequence follows directly from structure 3:

### 4. The two-hop cost of secondary indexes on a clustered index

Once there's no heap to point into, a secondary index (say, on `email`) can't store a physical rowid. It stores the clustering key instead, then does a second lookup into the clustered B-tree index to fetch the row.

[![Secondary index pointing into a clustered index](/images/posts/04-secondary-index-over-clustered-index.svg)](/images/posts/04-secondary-index-over-clustered-index.svg)

**_This two-hop pattern is exactly what Kleppmann and Riccomini are describing when they discuss the cost of secondary indexes on clustered-index tables in DDIA book!_** 

By the way, Winand lays out exactly why this hurts once you add a second index on top of a clustered one. As the rows inside an index-organized table can move at any time to preserve B-tree order, a secondary index can't store a physical pointer (_rowid_) to them, so it has to store the clustering key (often the primary key) instead and use that to look the row up. 

In practice, this means every lookup through a secondary index costs two searches instead of one: an INDEX RANGE SCAN on the secondary index, followed by an INDEX UNIQUE SCAN into the clustered index for each match. As Winand puts it, _"accessing an index-organized table via a secondary index is very inefficient."_ 

The fix is the same one used for heap tables: an index-only scan, though here it's better described as a "secondary-index-only scan"; and the payoff is even bigger, since it eliminates an entire INDEX UNIQUE SCAN per row rather than a single table access.

## Why the definitions collided

- __Oracle__ calls this structure an *index-organized table* and reserves *cluster* for something unrelated (i.e., multiple tables sharing storage blocks by a cluster key);
- **MySQL/InnoDB and Microsoft SQL Server** call the same structure a *clustered index*;
- __Classical database texts__ like Silberschatz et al's and Navathe et al's are describing a *different* axis of classification: does index order match file order? Not whether the heap exists at all...
- __IBM Db2__ is the outlier that actually lines up with the classical texts: its clustering index is a genuinely separate object from the table, and Db2 tracks how well the two stay in sync, that is, the same axis Silberschatz is describing, not the IOT axis Oracle/MySQL/SQL Server are on.

Two structures, several vocabularies, one underlying set of concepts, with Db2 being the rare case where a vendor's terminology and the classical textbook terminology actually agree. But none of the sources is "wrong" in isolation; the confusion only shows up when you read across them, or cross-references them, which is exactly what happens in a book club drawing on multiple references.

## Bonus round: covering index (no controversy here!)

Not every indexing term is contested. While looking into this, I also revisited **covering index**, as defined in Markus Winand's [*SQL Performance Explained*](https://sql-performance-explained.com) (2025). Unlike the clustered/clustering mess, this one is consistent everywhere: SQL Server docs, PostgreSQL literature, Couchbase docs, and Winand's book all agree:

> A **covering index** contains every column a query needs —`SELECT`-list columns as well as`WHERE`and`JOIN` columns —, so the database engine never has to visit the underlying table at all.

[![Covering index compared to a non-covering index](/images/posts/05-covering-index.svg)](/images/posts/05-covering-index.svg)

Or specifically quoting Winand's book:

> _"If an index prevents a table access it is also called a **covering index**.The term is misleading, however, because it sounds like an index property. The phrase index-only scan correctly suggests that it is an execution plan operation."_

The nice part: this concept is orthogonal to the clustering debate above. It applies whether you're skipping a hop to a heap file (Silberschatz et al's clustering index) or skipping a hop into a clustered B-tree (DDIA's clustered index). 

By the way, a [YugaByte's blog post](https://www.yugabyte.com/blog/how-a-distributed-sql-database-boosts-secondary-index-queries-with-index-only-scan/) goes further by citing other covering indexes' diverse names:

> _"The solution is simple and has many names: "covering index", "include index", "projection index", "fat index" and even "Tapio index" from the name of the author of “Interscience Relational Database Index Design and the Optimizers” (Tapio Lahdenmäki) who explained this in detail."_

But, all in all, they're all aliases/nicknames for the same mechanism, not competing definitions. _Phew!_ 😅

## A key takeaway

If you're reading multiple database books then assume "clustered/clustering index" means different things depending on which book is in your hand, until proven otherwise. When in doubt, ask yourself: *is there a separate heap file here, or not?* That question cuts through the vocabulary every time.

![key-takeway](/images/posts/heap_file_decision_takeaway.svg)

__Cheers!<br/>
Edward__


_PS: I checked whether this is a known erratum in DDIA and it isn't, __understandly so because it isn’t an error!__ `¯\_(ツ)_/¯` Nevertheless, I did suggest a clarifying footnote to O'Reilly, since a one-line pointer to the academic usage might save the next reader the doubt I had._

---

_August, 28th, 2026_