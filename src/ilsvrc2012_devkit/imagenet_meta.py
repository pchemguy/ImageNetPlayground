"""
imagenet_meta.py
----------------


Usage:    
    from imagenet_meta import ImageNetMeta

    meta = ImageNetMeta("ILSVRC2012_devkit/data/meta.mat")

    print(meta.get_synset(1))
    print(meta.id_to_words[281])

"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List

import scipy.io


@dataclass(frozen=True)
class Synset:
    ilsvrc_id: int
    wnid: str
    words: str
    num_children: int
    children: List[int]
    wordnet_height: int
    num_train_images: int


class ImageNetMeta:
    def __init__(self, meta_mat_path: str | Path):
        meta_mat_path = Path(meta_mat_path)
        if not meta_mat_path.exists():
            raise FileNotFoundError(meta_mat_path)

        mat = scipy.io.loadmat(meta_mat_path, squeeze_me=True)
        raw_synsets = mat["synsets"]

        synsets: Dict[int, Synset] = {}

        for s in raw_synsets:
            ilsvrc_id = int(s["ILSVRC2012_ID"])

            children = s["children"]
            if hasattr(children, "tolist"):
                children = children.tolist()
            elif children is None:
                children = []
            else:
                children = [int(children)]

            synsets[ilsvrc_id] = Synset(
                ilsvrc_id=ilsvrc_id,
                wnid=str(s["WNID"]),
                words=str(s["words"]),
                num_children=int(s["num_children"]),
                children=[int(c) for c in children],
                wordnet_height=int(s["wordnet_height"]),
                num_train_images=int(s["num_train_images"]),
            )

        self.synsets = synsets

        # Canonical subsets
        self.leaf_ids = [i for i in synsets if i <= 1000]
        self.internal_ids = [i for i in synsets if i > 1000]

        # Common mappings
        self.id_to_wnid = {i: s.wnid for i, s in synsets.items()}
        self.wnid_to_id = {s.wnid: i for i, s in synsets.items()}
        self.id_to_words = {i: s.words for i, s in synsets.items()}

    def get_leaf_synsets(self) -> List[Synset]:
        return [self.synsets[i] for i in self.leaf_ids]

    def get_synset(self, ilsvrc_id: int) -> Synset:
        return self.synsets[ilsvrc_id]
