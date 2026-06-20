# Real-reference library

This folder contains research references, not runtime textures. `.gdignore`
keeps the library out of Godot's importer.

## Admission rule

An image can enter this library only when its per-file manifest records:

- source page and original file URL;
- author and exact license;
- commercial, derivative, and redistribution rights;
- identifiable people and a separate personality/publicity-rights decision;
- acquisition date and SHA-256 hash;
- coverage role such as front, rear, side, joint, material, or context;
- review status and downstream game assets that use it.

Search engines, Pinterest, Facebook, Street View captures, and images with an
unknown or non-derivative license are scouting sources only and must not be
committed here.

Copyright permission does not automatically clear personality, privacy,
trademark, site-access, or cultural-property restrictions. `reference_only`
describes use inside production; it does not approve public redistribution.

## Geometry rule

Four sides are a minimum coverage check, not permission to invent hidden
geometry. Hero architecture additionally needs diagonal views, roof/underside
coverage, measured dimensions, and close-ups of structural joins. Unknown
areas remain marked `unknown` until evidence exists.

## Acquisition

Reviewed Wikimedia Commons batches can be acquired with:

```powershell
.\tools\acquire_commons_reference.ps1 `
  -TitlesFile .\reference-library\chua-cau-2024\titles.txt `
  -OutputDirectory .\reference-library\chua-cau-2024 `
  -Originals
```

The script intentionally accepts only CC0, public-domain, and CC BY files.
CC BY-SA and other licenses require a separate legal and distribution review.
