## Tips & Tricks

With any software there are some tips and tricks that allow the user to efficiently and effectively get the results as desired. In this document, some details are provided to avoid the common pitfalls in the workflow.

1. **Supported geometry formats**: GenSDF natively reads triangulated OBJ files (with vertex normals) and binary STL files. The format is detected automatically from the file extension (`.stl` / `.STL` → binary STL; anything else → OBJ). For other CAD formats, load the geometry using trimesh and export as OBJ or binary STL:
   ```python
   import trimesh
   mesh = trimesh.load("mygeometry.step")
   mesh.export("mygeometry.obj")          # OBJ with normals
   # or
   mesh.export("mygeometry.stl")          # binary STL
   ```
2. Make sure that OBJ geometry has outward vertex normals contained in its definition. If this information is not available, simply pass the OBJ file through trimesh and re-export:
   `mymesh.export("mygeometry.obj", include_normals=True)`
3. In some cases you will observe that the computational grid is relatively finer than the surface triangulation on the geometry. Sometimes this can lead to holes in the generated SDF. To resolve this issue, you can use the `wrapwrap` [https://github.com/ipadjen/wrapwrap] tool to shrink wrap the geometry with a finer surface triangulation. This is especially true for geometry with large triangular faces such as cities, square blocks, and other flat or box like geometry.
