ALTER TABLE "synsets"
DROP COLUMN "sid";

ALTER TABLE "synsets"
ADD COLUMN "sid" TEXT COLLATE NOCASE
GENERATED ALWAYS AS (metadata ->> '$.identifier') VIRTUAL;

CREATE UNIQUE INDEX "synset_sid_index" ON "synsets" ("sid");
