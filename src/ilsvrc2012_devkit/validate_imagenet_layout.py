"""
validate_imagenet_layout.py
---------------------------

Usage:
    meta = ImageNetMeta("ILSVRC2012_devkit/data/meta.mat")
    validate_imagenet_train(
        "imagenet/train",
        meta,
        check_counts=True,
    )

"""


from pathlib import Path
from imagenet_meta import ImageNetMeta


def validate_imagenet_train(
    train_root: str | Path,
    meta: ImageNetMeta,
    check_counts: bool = False,
):
    train_root = Path(train_root)
    if not train_root.exists():
        raise FileNotFoundError(train_root)

    expected_wnids = {
        meta.synsets[i].wnid for i in meta.leaf_ids
    }

    found_wnids = {
        p.name for p in train_root.iterdir() if p.is_dir()
    }

    missing = expected_wnids - found_wnids
    extra = found_wnids - expected_wnids

    if missing:
        raise RuntimeError(f"Missing class folders: {sorted(missing)[:5]}...")

    if extra:
        raise RuntimeError(f"Unexpected class folders: {sorted(extra)[:5]}...")

    if check_counts:
        for wnid in expected_wnids:
            ilsvrc_id = meta.wnid_to_id[wnid]
            expected = meta.synsets[ilsvrc_id].num_train_images
            actual = len(list((train_root / wnid).glob("*.JPEG")))

            if actual != expected:
                print(
                    f"[WARN] {wnid}: expected {expected}, found {actual}"
                )

    print("ImageNet training directory validated successfully.")
