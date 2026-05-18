module flood_fill_mod
    !
    ! flood_fill_mod — iterative flood-fill sign-determination.
    !
    use utils_io, only : dp, scalarvalue
    implicit none

contains

    subroutine fill_internal(grid, inx, iny, inz, sx, sy, sz, ex, ey, ez, large_negative_value)
        !
        ! Mark positive cells enclosed by the geometry surface with large_negative_value.
        !
        implicit none
        integer,  intent(in)    :: inx, iny, inz
        integer,  intent(in)    :: sx, sy, sz, ex, ey, ez
        real(dp), intent(in)    :: large_negative_value
        real(dp), intent(inout) :: grid(inx, iny, inz)

        integer,  allocatable :: stack(:,:), tmp_stack(:,:)
        ! flag: 0=unknown, 1=exterior, 2=interior
        integer,  allocatable :: flag(:,:,:)
        integer :: ii, jj, kk, ci, cj, ck, ni, nj, nk, top, i_dir
        integer, parameter :: n_dirs = 6
        integer :: dirs(3,n_dirs) = reshape([ &
            1, 0, 0,  -1, 0, 0, &
            0, 1, 0,   0,-1, 0, &
            0, 0, 1,   0, 0,-1], shape=[3,n_dirs])
        real(dp), parameter :: SENTINEL_FRAC = 0.5_dp
        integer :: stack_size

        ! Start with a modest stack size; double when needed
        stack_size = 1024
        allocate(flag(sx:ex, sy:ey, sz:ez))
        allocate(stack(3, stack_size))
        flag = 0

        ! 
        ! Pass 1: BFS from domain boundary through sentinel cells -> EXTERIOR
        ! 
        top = 0
        do kk = sz, ez; do jj = sy, ey; do ii = sx, ex
            if (ii==sx .or. ii==ex .or. jj==sy .or. jj==ey .or. kk==sz .or. kk==ez) then
                if (grid(ii,jj,kk) > 0.0_dp .and. &
                    abs(grid(ii,jj,kk)) >= scalarvalue * SENTINEL_FRAC) then
                    flag(ii,jj,kk) = 1   ! exterior
                    top = top + 1
                    if (top > stack_size) then
                        stack_size = stack_size * 2
                        allocate(tmp_stack(3, stack_size))
                        tmp_stack(:, 1:top-1) = stack(:, 1:top-1)
                        call move_alloc(tmp_stack, stack)
                    end if
                    stack(:,top) = [ii,jj,kk]
                end if
            end if
        end do; end do; end do

        do while (top > 0)
            ci = stack(1,top); cj = stack(2,top); ck = stack(3,top)
            top = top - 1
            do i_dir = 1, n_dirs
                ni = ci + dirs(1,i_dir)
                nj = cj + dirs(2,i_dir)
                nk = ck + dirs(3,i_dir)
                if (ni>=sx .and. ni<=ex .and. nj>=sy .and. nj<=ey .and. nk>=sz .and. nk<=ez) then
                    if (flag(ni,nj,nk) == 0 .and. &
                        abs(grid(ni,nj,nk)) >= scalarvalue * SENTINEL_FRAC) then
                        flag(ni,nj,nk) = 1
                        top = top + 1
                        if (top > stack_size) then
                            stack_size = stack_size * 2
                            allocate(tmp_stack(3, stack_size))
                            tmp_stack(:, 1:top-1) = stack(:, 1:top-1)
                            call move_alloc(tmp_stack, stack)
                        end if
                        stack(:,top) = [ni,nj,nk]
                    end if
                end if
            end do
        end do

        ! 
        ! Pass 2: BFS from interior seeds (sentinel cells adjacent to
        !         narrowband-negative cells) -> INTERIOR
        ! 
        top = 0
        do kk = sz, ez; do jj = sy, ey; do ii = sx, ex
            if (flag(ii,jj,kk) /= 0) cycle   ! already classified
            if (abs(grid(ii,jj,kk)) < scalarvalue * SENTINEL_FRAC) cycle  ! narrowband cell
            ! Candidate interior sentinel: check if any neighbour is narrowband-negative
            do i_dir = 1, n_dirs
                ni = ii + dirs(1,i_dir)
                nj = jj + dirs(2,i_dir)
                nk = kk + dirs(3,i_dir)
                if (ni>=sx .and. ni<=ex .and. nj>=sy .and. nj<=ey .and. nk>=sz .and. nk<=ez) then
                    if (grid(ni,nj,nk) < 0.0_dp .and. &
                        abs(grid(ni,nj,nk)) < scalarvalue * SENTINEL_FRAC) then
                        ! Neighbour is a narrowband interior cell -> this cell is interior
                        flag(ii,jj,kk) = 2
                        top = top + 1
                        if (top > stack_size) then
                            stack_size = stack_size * 2
                            allocate(tmp_stack(3, stack_size))
                            tmp_stack(:, 1:top-1) = stack(:, 1:top-1)
                            call move_alloc(tmp_stack, stack)
                        end if
                        stack(:,top) = [ii,jj,kk]
                        exit
                    end if
                end if
            end do
        end do; end do; end do

        do while (top > 0)
            ci = stack(1,top); cj = stack(2,top); ck = stack(3,top)
            top = top - 1
            do i_dir = 1, n_dirs
                ni = ci + dirs(1,i_dir)
                nj = cj + dirs(2,i_dir)
                nk = ck + dirs(3,i_dir)
                if (ni>=sx .and. ni<=ex .and. nj>=sy .and. nj<=ey .and. nk>=sz .and. nk<=ez) then
                    if (flag(ni,nj,nk) == 0 .and. &
                        abs(grid(ni,nj,nk)) >= scalarvalue * SENTINEL_FRAC) then
                        flag(ni,nj,nk) = 2
                        top = top + 1
                        if (top > stack_size) then
                            stack_size = stack_size * 2
                            allocate(tmp_stack(3, stack_size))
                            tmp_stack(:, 1:top-1) = stack(:, 1:top-1)
                            call move_alloc(tmp_stack, stack)
                        end if
                        stack(:,top) = [ni,nj,nk]
                    end if
                end if
            end do
        end do

        ! 
        ! Mark interior sentinel cells
        ! 
        do kk = sz, ez; do jj = sy, ey; do ii = sx, ex
            if (flag(ii,jj,kk) == 2 .and. grid(ii,jj,kk) > 0.0_dp) &
                grid(ii,jj,kk) = large_negative_value
        end do; end do; end do

        deallocate(flag, stack)
    end subroutine fill_internal

end module flood_fill_mod
