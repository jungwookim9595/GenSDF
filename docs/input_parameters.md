## Input Parameters

The input parameters file `parameters.in` looks as shown below.

```
# Name and location of the input geometry file (.obj or binary .stl)
'data/armadillo_withnormals.obj'
# scalarvalue (real), buffer_points (int), progressbarwidth (int)
100.0 10 20
# nx, ny, nz (Computational Grid)
512 128 128
# r0 — origin of the computational grid (x, y, z)
0.0 0.0 0.0
# non_uniform_grid (.true. / .false.)
.true.
# use_fast_sweep (.true. / .false.)
.true.
# narrow_band_width (int) — only used when use_fast_sweep = .true.
6
# vertical_axis (2 = y is wall-normal, 3 = z is wall-normal)
3
# compute_face_sdf (.true. / .false.)
.false.
```

Lines whose first non-blank character is `#` are comments and are ignored by the reader. Blank lines are also ignored.

1. `'data/armadillo_withnormals.obj'` — Path to the geometry file. Supported formats:
   - **OBJ** (ASCII, triangulated, must contain vertex normals `vn`). The file extension is anything other than `.stl`/`.STL`.
   - **Binary STL** (little-endian, standard 50-byte-per-triangle layout). Detected automatically when the filename ends in `.stl` or `.STL`.

2. `100.0 10 20`
   - `100.0` — Large sentinel value assigned to grid points outside the bounding box where the SDF is not computed. Must be larger than the largest expected distance in the domain.
   - `10` — Buffer width (number of grid points) added around the geometry bounding box; controls how far the narrow-band/brute-force distance is computed.
   - `20` — Progress-bar width in characters. Adjust to match your terminal width (typically 20–40).

3. `512 128 128` — Number of grid points in $x$, $y$, $z$ (after any axis permutation, see `vertical_axis`).

4. `0.0 0.0 0.0` — Origin of the computational domain, matching the `r0` vector in CaNS's `geometry.out`.

5. `F` — Non-uniform grid flag. Set to `T` if the wall-normal direction uses a stretched grid (e.g. from CaNS). When `T`, the cell-face coordinates are read from `data/grid.out` (columns 2 and 3 are cell-centre and face positions in the wall-normal direction). For a uniform grid use `F`.

6. `F` — Fast Sweep Method flag. When `F` (default), the brute-force point-to-triangle distance is used for every grid point inside the bounding box. When `T`, only a narrow band of width `narrow_band_width` cells is initialised by brute force and the Godunov Fast Sweeping Method (FSM) is used to propagate the SDF to the rest of the domain. FSM is significantly faster for large grids with wide bounding boxes.

7. `6` — Narrow-band half-width in grid cells, used only when `use_fast_sweep = .true.`. A value of 4–8 is typically sufficient.

8. `3` — Wall-normal axis of the solver coordinate system.
   - `3` (default): $z$ is wall-normal. GenSDF reads grid coordinates as $(x, y, z)$ with no permutation.
   - `2`: $y$ is wall-normal. GenSDF internally permutes axes so that its wall-normal direction is always dimension 3; the geometry and grid are reordered accordingly before computation.

9. `F` — Face-SDF flag. When `F` (default), only the cell-centre field `data/sdfp.bin` is written. When `T`, the three face-staggered fields `data/sdfu.bin`, `data/sdfv.bin`, and `data/sdfw.bin` are also computed and written (in addition to `sdfp.bin`).
