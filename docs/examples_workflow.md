# Workflow using GenSDF

Once you have sucessfully compiled the software, you can follow the instructions below to run the example case listed in the `example` directory of the repository.

1. Fetch the "Armadillo" OBJ file from the openly available location. Credits to `alecjacobson` making the OBJ file openly available. 

   ```
   cd example/data      
   chmod +x fetchArmadillo.sh
   ./fetchArmadillo.sh
   ```
   This will download the required geometry to the data folder.
2. Since the geometry is not scaled to fit on grid provided in the example, we must scale it to the appropriate size.
   ```
   python rescale_geometry.py
   ```
    In this step the python script will rescale the geometry to fit within the grid as well as output the vertex outward normals in the OBJ file. This step is crucial as the software will raise an error if the geometry does not contain vertex normals information.
3. Navigate to the source directory, compile, and copy the executable to the example folder
   ```
   cd ../../src
   make
   cp gensdf ../../example/
   cd ../../example/
   ```
   > **Note:** The `example/parameters.in` uses the old `!` comment style. Before running, update it to use `#` for comment lines and add the four new parameters (`use_fast_sweep`, `narrow_band_width`, `vertical_axis`, `compute_face_sdf`) — see `docs/input_parameters.md` for the full format.
4. Execute the code with MPI
   ```
   mpirun -np 4 ./gensdf
   ```
   You will get output that looks as shown below.
   ```
    ░▒▓██████▓▒░░▒▓████████▓▒░▒▓███████▓▒░ ░▒▓███████▓▒░▒▓███████▓▒░░▒▓████████▓▒░ 
   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
   ░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
   ░▒▓█▓▒▒▓███▓▒░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░   
   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
    ░▒▓██████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓███████▓▒░░▒▓█▓▒░        
   *** Starting with            4 MPI ranks ***
   *** Input file successfully read ***
   *** Successfully read the grid ***
   *** Successfully set up grid spacing ***
   Successfully read OBJ: data/armadillo_withnormals.obj
   Vertices:        49990   Normals:        49990   Faces:        99976
   Geometry bbox min:  12.000   0.500   0.500
   Geometry bbox max:  16.000   5.265   4.135
   AABB x:   182  11.375  |   266  16.625
   AABB y:     1   0.031  |    94   5.844
   AABB z:     1   0.031  |    76   4.719
   -- Pre-processing done in   0.36 s
   -- Estimated minimum memory:  0.14  GiB(s)
   *** Calculating SDF | cell-centres ***
   ||||||||||||||||||||||100.00%    99976/   99976 Elapsed:    11.92s Remaining:     0.00s
   *** Writing | cell-centres ***
   -- Write done in   0.026 s | cell-centres
   *** SDF complete in   47.85 s ***
   ```
5. Once the SDF is generated, you can visualise it in Paraview using the `read_xmf_constant_grid.xmf` script. Use the default XDMF reader — the other two options may crash the session.
6. To visualise the geometry surface, plot the contour at a value of 0.

## MPI notes

GenSDF is MPI-only; there is no separate serial build. The single executable `gensdf` is compiled from `src/`.

- Ensure the MPI library is correctly sourced in your terminal environment before compiling and running.
- Running with a single rank (`mpirun -np 1 ./gensdf`) is supported.
- Because the domain decomposition splits the geometry bounding box along $x$, using more MPI ranks than there are $x$-cells inside the bounding box is not useful and may produce empty slabs for some ranks. Keep the rank count commensurate with the bounding-box extent.