"""
plot_sdf.py
-----------
Load sdfp.bin and either:
  - plot the x-z plane (y-normal slice) at a user-specified y height  [default]
  - extract and display the SDF = 0 isosurface in 3D                  [--iso]

Usage:
    python3 plot_sdf.py              # x-z slice at Y_HEIGHT default
    python3 plot_sdf.py 0.05         # x-z slice at y = 0.05 m
    python3 plot_sdf.py --iso        # 3-D isosurface (requires scikit-image)

Binary format: big-endian float64, Fortran column-major, shape (nx+2, ny+2, nz).
"""

import sys
import numpy as np
import matplotlib.pyplot as plt

# =============================================================================
#  USER PARAMETERS
# =============================================================================
Y_HEIGHT  = 0.05        # y coordinate [m] of the slice — override on command line
ISO_MODE  = '--iso' in sys.argv
args      = [a for a in sys.argv[1:] if not a.startswith('--')]

if args:
    Y_HEIGHT = float(args[0])

# =============================================================================
#  PATHS
# =============================================================================
DATA_DIR  = 'data/'
SDF_FILE  = DATA_DIR + 'sdfp.bin'
GRID_FILE = DATA_DIR + 'grid.out'
GEOM_FILE = DATA_DIR + 'geometry.out'

# =============================================================================
#  READ GEOMETRY
# =============================================================================
with open(GEOM_FILE) as fh:
    lines = [l.strip() for l in fh if l.strip()]
nx, ny, nz = (int(v)   for v in lines[0].split())
Lx, Ly, Lz = (float(v) for v in lines[1].split())

# =============================================================================
#  COORDINATES
# =============================================================================
dx = Lx / nx
dz = Lz / nz
x  = np.linspace(dx / 2.0, Lx - dx / 2.0, nx)   # uniform cell centres
z  = np.linspace(dz / 2.0, Lz - dz / 2.0, nz)   # uniform cell centres

grid_data = np.loadtxt(GRID_FILE)
y = grid_data[:, 1]   # non-uniform wall-normal cell centres

# =============================================================================
#  READ SDF
# =============================================================================
raw = np.fromfile(SDF_FILE, dtype='>f8')   # big-endian float64
sdf = raw.reshape((nx + 2, ny + 2, nz), order='F')[1:nx + 1, 1:ny + 1, :]

# =============================================================================
#  3-D ISOSURFACE  (--iso)
# =============================================================================
if ISO_MODE:
    try:
        from skimage.measure import marching_cubes
    except ImportError:
        sys.exit('scikit-image is required for --iso:  pip install scikit-image')
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection

    print('Extracting SDF = 0 isosurface via marching cubes …')
    # Run marching cubes with unit y-spacing; remap y vertices to physical coords
    # afterwards so that non-uniform wall-normal grids are handled correctly.
    verts, faces, _, _ = marching_cubes(sdf, level=0.0, spacing=(dx, 1.0, dz))

    # verts[:, 1] is a float index into the y array — interpolate to metres.
    iy_lo    = np.clip(verts[:, 1].astype(int), 0, ny - 2)
    frac     = verts[:, 1] - iy_lo
    y_phys   = y[iy_lo] + frac * (y[iy_lo + 1] - y[iy_lo])
    verts_p  = np.column_stack([verts[:, 0], y_phys, verts[:, 2]])

    print(f'  {len(faces):,} triangles,  {len(verts_p):,} vertices')

    fig3d = plt.figure(figsize=(10, 8))
    ax3d  = fig3d.add_subplot(111, projection='3d')
    poly  = Poly3DCollection(verts_p[faces], alpha=0.55,
                             facecolor='steelblue', edgecolor='none')
    ax3d.add_collection3d(poly)

    ax3d.set_xlim(0,    Lx)
    ax3d.set_ylim(y[0], y[-1])
    ax3d.set_zlim(0,    Lz)
    ax3d.set_xlabel('x [m]')
    ax3d.set_ylabel('y [m]')
    ax3d.set_zlabel('z [m]')
    ax3d.set_title('SDF = 0 isosurface')
    fig3d.tight_layout()
    plt.show()

# =============================================================================
#  x-z SLICE  (default)
# =============================================================================
else:
    iy = int(np.argmin(np.abs(y - Y_HEIGHT)))
    print(f'Requested y = {Y_HEIGHT:.4f} m  →  nearest cell y = {y[iy]:.4f} m  (iy={iy})')

    slice_xz = sdf[:, iy, :]          # shape (nx, nz)
    vmax = np.percentile(np.abs(slice_xz), 10)

    XX, ZZ = np.meshgrid(x, z, indexing='ij')

    fig, ax = plt.subplots(figsize=(10, 4))
    im = ax.pcolormesh(XX, ZZ, slice_xz, cmap='RdBu_r', vmin=-vmax, vmax=vmax,
                       shading='nearest')
    ax.contour(XX, ZZ, slice_xz, levels=[0.0], colors='k', linewidths=0.8)

    cb = fig.colorbar(im, ax=ax, pad=0.02)
    cb.set_label('SDF [m]')

    ax.set_xlabel('x [m]')
    ax.set_ylabel('z [m]')
    ax.set_title(f'SDF  —  x-z slice at y = {y[iy]:.4f} m  (iy={iy})')
    ax.set_aspect('equal')
    fig.tight_layout()
    plt.show()
