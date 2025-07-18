-- written by groverbuger for g3d
-- january 2021
-- MIT license


local vectors = {}
-- written by groverbuger for g3d
-- february 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- vector functions
----------------------------------------------------------------------------------------------------
-- some basic vector functions that don't use tables
-- because these functions will happen often, this is done to avoid frequent memory allocation

function vectors.subtract(v1,v2,v3, v4,v5,v6)
    return v1-v4, v2-v5, v3-v6
end

function vectors.add(v1,v2,v3, v4,v5,v6)
    return v1+v4, v2+v5, v3+v6
end

function vectors.scalarMultiply(scalar, v1,v2,v3)
    return v1*scalar, v2*scalar, v3*scalar
end

function vectors.crossProduct(a1,a2,a3, b1,b2,b3)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

function vectors.dotProduct(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

function vectors.normalize(x,y,z)
    local mag = math.sqrt(x^2 + y^2 + z^2)
    return x/mag, y/mag, z/mag
end

function vectors.magnitude(x,y,z)
    return math.sqrt(x^2 + y^2 + z^2)
end


local fastSubtract = vectors.subtract
local vectorAdd = vectors.add
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize
local vectorMagnitude = vectors.magnitude

----------------------------------------------------------------------------------------------------
-- collision detection functions
----------------------------------------------------------------------------------------------------
--
-- none of these functions are required for developing 3D games
-- however these collision functions are very frequently used in 3D games
--
-- be warned! a lot of this code is butt-ugly
-- using a table per vector would create a bazillion tables and lots of used memory
-- so instead all vectors are all represented using three number variables each
-- this approach ends up making the code look terrible, but collision functions need to be efficient

local collisions = {}

-- finds the closest point to the source point on the given line segment
local function closestPointOnLineSegment(
        a_x,a_y,a_z, -- point one of line segment
        b_x,b_y,b_z, -- point two of line segment
        x,y,z        -- source point
    )
    local ab_x, ab_y, ab_z = b_x - a_x, b_y - a_y, b_z - a_z
    local t = vectorDotProduct(x - a_x, y - a_y, z - a_z, ab_x, ab_y, ab_z) / (ab_x^2 + ab_y^2 + ab_z^2)
    t = math.min(1, math.max(0, t))
    return a_x + t*ab_x, a_y + t*ab_y, a_z + t*ab_z
end

-- model - ray intersection
-- based off of triangle - ray collision from excessive's CPML library
-- does a triangle - ray collision for every face in the model to find the shortest collision
--
-- sources:
--     https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--     http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
local tiny = 2.2204460492503131e-16 -- the smallest possible value for a double, "double epsilon"
local function triangleRay(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        src_x, src_y, src_z,
        dir_x, dir_y, dir_z
    )

    -- cache these variables for efficiency
    local e11,e12,e13 = fastSubtract(tri_1_x,tri_1_y,tri_1_z, tri_0_x,tri_0_y,tri_0_z)
    local e21,e22,e23 = fastSubtract(tri_2_x,tri_2_y,tri_2_z, tri_0_x,tri_0_y,tri_0_z)
    local h1,h2,h3 = vectorCrossProduct(dir_x,dir_y,dir_z, e21,e22,e23)
    local a = vectorDotProduct(h1,h2,h3, e11,e12,e13)

    -- if a is too close to 0, ray does not intersect triangle
    if math.abs(a) <= tiny then
        return
    end

    local s1,s2,s3 = fastSubtract(src_x,src_y,src_z, tri_0_x,tri_0_y,tri_0_z)
    local u = vectorDotProduct(s1,s2,s3, h1,h2,h3) / a

    -- ray does not intersect triangle
    if u < 0 or u > 1 then
        return
    end

    local q1,q2,q3 = vectorCrossProduct(s1,s2,s3, e11,e12,e13)
    local v = vectorDotProduct(dir_x,dir_y,dir_z, q1,q2,q3) / a

    -- ray does not intersect triangle
    if v < 0 or u + v > 1 then
        return
    end

    -- at this stage we can compute t to find out where
    -- the intersection point is on the line
    local thisLength = vectorDotProduct(q1,q2,q3, e21,e22,e23) / a

    -- if hit this triangle and it's closer than any other hit triangle
    if thisLength >= tiny and (not finalLength or thisLength < finalLength) then
        --local norm_x, norm_y, norm_z = vectorCrossProduct(e11,e12,e13, e21,e22,e23)

        return thisLength, src_x + dir_x*thisLength, src_y + dir_y*thisLength, src_z + dir_z*thisLength, n_x,n_y,n_z
    end
end

-- detects a collision between a triangle and a sphere
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function triangleSphere(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        tri_n_x, tri_n_y, tri_n_z,
        src_x, src_y, src_z, radius
    )

    -- recalculate surface normal of this triangle
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    -- distance from src to a vertex on the triangle
    local dist = vectorDotProduct(src_x - tri_0_x, src_y - tri_0_y, src_z - tri_0_z, n_x, n_y, n_z)

    -- collision not possible, just return
    if dist < -radius or dist > radius then
        return
    end

    -- itx stands for intersection
    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- determine whether itx is inside the triangle
    -- project it onto the triangle and return if this is the case
    local c0_x, c0_y, c0_z = vectorCrossProduct(itx_x - tri_0_x, itx_y - tri_0_y, itx_z - tri_0_z, tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z)
    local c1_x, c1_y, c1_z = vectorCrossProduct(itx_x - tri_1_x, itx_y - tri_1_y, itx_z - tri_1_z, tri_2_x - tri_1_x, tri_2_y - tri_1_y, tri_2_z - tri_1_z)
    local c2_x, c2_y, c2_z = vectorCrossProduct(itx_x - tri_2_x, itx_y - tri_2_y, itx_z - tri_2_z, tri_0_x - tri_2_x, tri_0_y - tri_2_y, tri_0_z - tri_2_z)
    if  vectorDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z
        
        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    -- itx is outside triangle
    -- find points on all three line segments that are closest to itx
    -- if distance between itx and one of these three closest points is in range, there is an intersection
    local radiussq = radius * radius
    local smallestDist

    local line1_x, line1_y, line1_z = closestPointOnLineSegment(tri_0_x, tri_0_y, tri_0_z, tri_1_x, tri_1_y, tri_1_z, src_x, src_y, src_z)
    local dist = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2
    if dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line1_x, line1_y, line1_z
    end

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(tri_1_x, tri_1_y, tri_1_z, tri_2_x, tri_2_y, tri_2_z, src_x, src_y, src_z)
    local dist = (src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2
    if (smallestDist and dist < smallestDist or not smallestDist) and dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
    end

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(tri_2_x, tri_2_y, tri_2_z, tri_0_x, tri_0_y, tri_0_z, src_x, src_y, src_z)
    local dist = (src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2
    if (smallestDist and dist < smallestDist or not smallestDist) and dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
    end

    if smallestDist then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end
end

-- finds the closest point on the triangle from the source point given
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function trianglePoint(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        tri_n_x, tri_n_y, tri_n_z,
        src_x, src_y, src_z
    )

    -- recalculate surface normal of this triangle
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    -- distance from src to a vertex on the triangle
    local dist = vectorDotProduct(src_x - tri_0_x, src_y - tri_0_y, src_z - tri_0_z, n_x, n_y, n_z)

    -- itx stands for intersection
    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- determine whether itx is inside the triangle
    -- project it onto the triangle and return if this is the case
    local c0_x, c0_y, c0_z = vectorCrossProduct(itx_x - tri_0_x, itx_y - tri_0_y, itx_z - tri_0_z, tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z)
    local c1_x, c1_y, c1_z = vectorCrossProduct(itx_x - tri_1_x, itx_y - tri_1_y, itx_z - tri_1_z, tri_2_x - tri_1_x, tri_2_y - tri_1_y, tri_2_z - tri_1_z)
    local c2_x, c2_y, c2_z = vectorCrossProduct(itx_x - tri_2_x, itx_y - tri_2_y, itx_z - tri_2_z, tri_0_x - tri_2_x, tri_0_y - tri_2_y, tri_0_z - tri_2_z)
    if  vectorDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    -- itx is outside triangle
    -- find points on all three line segments that are closest to itx
    -- if distance between itx and one of these three closest points is in range, there is an intersection
    local line1_x, line1_y, line1_z = closestPointOnLineSegment(tri_0_x, tri_0_y, tri_0_z, tri_1_x, tri_1_y, tri_1_z, src_x, src_y, src_z)
    local dist = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2
    local smallestDist = dist
    itx_x, itx_y, itx_z = line1_x, line1_y, line1_z

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(tri_1_x, tri_1_y, tri_1_z, tri_2_x, tri_2_y, tri_2_z, src_x, src_y, src_z)
    local dist = (src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2
    if smallestDist and dist < smallestDist then
        smallestDist = dist
        itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
    end

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(tri_2_x, tri_2_y, tri_2_z, tri_0_x, tri_0_y, tri_0_z, src_x, src_y, src_z)
    local dist = (src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2
    if smallestDist and dist < smallestDist then
        smallestDist = dist
        itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
    end

    if smallestDist then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end
end

-- finds the collision point between a triangle and a capsule
-- capsules are defined with two points and a radius
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function triangleCapsule(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        tip_x, tip_y, tip_z,
        base_x, base_y, base_z,
        a_x, a_y, a_z,
        b_x, b_y, b_z,
        capn_x, capn_y, capn_z,
        radius
    )

    -- find the normal of this triangle
    -- tbd if necessary, this sometimes fixes weird edgecases
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    local dotOfNormals = math.abs(vectorDotProduct(n_x, n_y, n_z, capn_x, capn_y, capn_z))

    -- default reference point to an arbitrary point on the triangle
    -- for when dotOfNormals is 0, because then the capsule is parallel to the triangle
    local ref_x, ref_y, ref_z = tri_0_x, tri_0_y, tri_0_z

    if dotOfNormals > 0 then
        -- capsule is not parallel to the triangle's plane
        -- find where the capsule's normal vector intersects the triangle's plane
        local t = vectorDotProduct(n_x, n_y, n_z, (tri_0_x - base_x) / dotOfNormals, (tri_0_y - base_y) / dotOfNormals, (tri_0_z - base_z) / dotOfNormals)
        local plane_itx_x, plane_itx_y, plane_itx_z = base_x + capn_x*t, base_y + capn_y*t, base_z + capn_z*t
        local _

        -- then clamp that plane intersect point onto the triangle itself
        -- this is the new reference point
        _, ref_x, ref_y, ref_z = trianglePoint(
            tri_0_x, tri_0_y, tri_0_z,
            tri_1_x, tri_1_y, tri_1_z,
            tri_2_x, tri_2_y, tri_2_z,
            n_x, n_y, n_z,
            plane_itx_x, plane_itx_y, plane_itx_z
        )
    end

    -- find the closest point on the capsule line to the reference point
    local c_x, c_y, c_z = closestPointOnLineSegment(a_x, a_y, a_z, b_x, b_y, b_z, ref_x, ref_y, ref_z)

    -- do a sphere cast from that closest point to the triangle and return the result
    return triangleSphere(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        c_x, c_y, c_z, radius
    )
end

-- finds whether or not a triangle is inside an AABB
local function triangleAABB(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        min_x, min_y, min_z,
        max_x, max_y, max_z
    )

    -- get the closest point from the centerpoint on the triangle
    local len,x,y,z,nx,ny,nz = trianglePoint(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        (min_x+max_x)*0.5, (min_y+max_y)*0.5, (min_z+max_z)*0.5
    )

    -- if the point is not inside the AABB, return nothing
    if not (x >= min_x and x <= max_x) then return end
    if not (y >= min_y and y <= max_y) then return end
    if not (z >= min_z and z <= max_z) then return end

    -- the point is inside the AABB, return the collision data
    return len, x,y,z, nx,ny,nz
end

local function rotate_euler(x, y, z, pitch, yaw, roll)
    local cp = math.cos(pitch)
    local sp = math.sin(pitch)
    local cy = math.cos(yaw)
    local sy = math.sin(yaw)
    local cr = math.cos(roll)
    local sr = math.sin(roll)

    -- Yaw (Y axis)
    local x1 = cy * x + sy * z
    local z1 = -sy * x + cy * z
    x, z = x1, z1

    -- Pitch (X axis)
    local y1 = cp * y - sp * z
    local z2 = sp * y + cp * z
    y, z = y1, z2

    -- Roll (Z axis)
    local x2 = cr * x - sr * y
    local y2 = sr * x + cr * y
    return x2, y2, z
end

-- runs a given intersection function on all of the triangles made up of a given vert table
local function findClosest(self, verts, func, ...)
    -- declare the variables that will be returned by the function
    local finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z

    -- cache references to this model's properties for efficiency
    local pitch = 0--self.rotation.x
    local yaw = 0--self.rotation.y
    local roll = 0--self.rotation.z
    local tx = self.translation.x
    local ty = self.translation.y
    local tz = self.translation.z
    local sx = 1--self.scale[1]
    local sy = 1--self.scale[2]
    local sz = 1--self.scale[3]

    -- NOTE: at this state doesn't applying rotation, but i dont care :3
    
    for v=1, #verts, 3 do
        -- apply the function given with the arguments given
        -- also supply the points of the current triangle
        local n_x, n_y, n_z = vectorNormalize(
            verts[v][6],
            verts[v][7],
            verts[v][8]
        )
        n_x, n_y, n_z = rotate_euler(n_x, n_y, n_z, pitch, yaw, roll)

        local function transform(i)
            local x = verts[i][1] * sx
            local y = verts[i][2] * sy
            local z = verts[i][3] * sz
            x, y, z = rotate_euler(x, y, z, pitch, yaw, roll)
            return x + tx, y + ty, z + tz
        end

        local ax, ay, az = transform(v)
        local bx, by, bz = transform(v + 1)
        local cx, cy, cz = transform(v + 2)

        local length, wx, wy, wz, nx, ny, nz = func(
            ax, ay, az,
            bx, by, bz,
            cx, cy, cz,
            n_x, n_y, n_z,
            ...
        )

        -- if something was hit
        -- and either the finalLength is not yet defined or the new length is closer
        -- then update the collision information
        if length and (not finalLength or length < finalLength) then
            finalLength = length
            where_x = wx
            where_y = wy
            where_z = wz
            norm_x = nx
            norm_y = ny
            norm_z = nz
        end
    end
    -- normalize the normal vector before it is returned
    if finalLength then
        norm_x, norm_y, norm_z = vectorNormalize(norm_x, norm_y, norm_z)
    end

    -- return all the information in a standardized way
    return finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z
end


function collisions:rayIntersection(collider, src_x, src_y, src_z, dir_x, dir_y, dir_z)
    return findClosest(self, collider, triangleRay, src_x, src_y, src_z, dir_x, dir_y, dir_z)
end

function collisions:sphereIntersection(collider, src_x, src_y, src_z, radius)
    return findClosest(self, collider, triangleSphere, src_x, src_y, src_z, radius)
end

function collisions:closestPoint(src_x, src_y, src_z)
    return findClosest(self, self.collider, trianglePoint, src_x, src_y, src_z)
end

function collisions:capsuleIntersection(tip_x, tip_y, tip_z, base_x, base_y, base_z, radius)
    -- the normal vector coming out the tip of the capsule
    local norm_x, norm_y, norm_z = vectorNormalize(tip_x - base_x, tip_y - base_y, tip_z - base_z)

    -- the base and tip, inset by the radius
    -- these two coordinates are the actual extent of the capsule sphere line
    local a_x, a_y, a_z = base_x + norm_x*radius, base_y + norm_y*radius, base_z + norm_z*radius
    local b_x, b_y, b_z = tip_x - norm_x*radius, tip_y - norm_y*radius, tip_z - norm_z*radius

    return findClosest(
        self,
        self.collider,
        triangleCapsule,
        tip_x, tip_y, tip_z,
        base_x, base_y, base_z,
        a_x, a_y, a_z,
        b_x, b_y, b_z,
        norm_x, norm_y, norm_z,
        radius
    )
end

function collisions:createCollisionZones(zoneSize)
    local aabb = self:generateAABB()

    local min_1 = math.floor(aabb.min[1]/zoneSize)*zoneSize
    local min_2 = math.floor(aabb.min[2]/zoneSize)*zoneSize
    local min_3 = math.floor(aabb.min[3]/zoneSize)*zoneSize

    local max_1 = math.floor(aabb.max[1]/zoneSize)*zoneSize
    local max_2 = math.floor(aabb.max[2]/zoneSize)*zoneSize
    local max_3 = math.floor(aabb.max[3]/zoneSize)*zoneSize

    local translation_x = self.translation[1]
    local translation_y = self.translation[2]
    local translation_z = self.translation[3]
    local scale_x = self.scale[1]
    local scale_y = self.scale[2]
    local scale_z = self.scale[3]
    local verts = self.verts

    local zones = {}
    for x=min_1, max_1, zoneSize do
        for y=min_2, max_2, zoneSize do
            for z=min_3, max_3, zoneSize do
                local hash = x .. ", " .. y .. ", " .. z

                for v=1, #verts, 3 do
                    local n_x, n_y, n_z = vectorNormalize(
                        verts[v][6]*scale_x,
                        verts[v][7]*scale_x,
                        verts[v][8]*scale_x
                    )

                    local inside = triangleAABB(
                        verts[v][1]*scale_x + translation_x,
                        verts[v][2]*scale_y + translation_y,
                        verts[v][3]*scale_z + translation_z,
                        verts[v+1][1]*scale_x + translation_x,
                        verts[v+1][2]*scale_y + translation_y,
                        verts[v+1][3]*scale_z + translation_z,
                        verts[v+2][1]*scale_x + translation_x,
                        verts[v+2][2]*scale_y + translation_y,
                        verts[v+2][3]*scale_z + translation_z,
                        n_x, n_y, n_z,
                        x,y,z,
                        x+zoneSize,y+zoneSize,z+zoneSize
                    )

                    if inside then
                        if not zones[hash] then
                            zones[hash] = {}
                        end

                        table.insert(zones[hash], verts[v])
                        table.insert(zones[hash], verts[v+1])
                        table.insert(zones[hash], verts[v+2])
                    end
                end
                
                if zones[hash] then
                    print(hash, #zones[hash])
                end
            end
        end
    end

    self.zones = zones
    return zones
end

----------------------------------------------------------------------------------------------------
-- AABB functions
----------------------------------------------------------------------------------------------------
-- generate an axis-aligned bounding box
-- very useful for less precise collisions, like hitboxes
--
-- translation, and scale are not included here because they are computed on the fly instead
-- rotation is never included because AABBs are axis-aligned
function collisions.generate_aabb_from_collider(collider)
    local aabb = {
        min = {
            math.huge,
            math.huge,
            math.huge,
        },
        max = {
            -1*math.huge,
            -1*math.huge,
            -1*math.huge
        }
    }

    for _,vert in ipairs(collider) do
        aabb.min[1] = math.min(aabb.min[1], vert[1])
        aabb.min[2] = math.min(aabb.min[2], vert[2])
        aabb.min[3] = math.min(aabb.min[3], vert[3])
        aabb.max[1] = math.max(aabb.max[1], vert[1])
        aabb.max[2] = math.max(aabb.max[2], vert[2])
        aabb.max[3] = math.max(aabb.max[3], vert[3])
    end
    return aabb
end


function collisions.generate_aabb_from_obb(obb)
    local absRight = vec3(math.abs(obb.right[1]), math.abs(obb.right[2]), math.abs(obb.right[3]))
    local absForward = vec3(math.abs(obb.forward[1]), math.abs(obb.forward[2]), math.abs(obb.forward[3]))
    local absUp = vec3(math.abs(obb.up[1]), math.abs(obb.up[2]), math.abs(obb.up[3]))

    local extents = absRight * obb.half_extents[1] + absUp * obb.half_extents[2] + absForward * obb.half_extents[3]

    local aabb = {min = {}, max = {}}
    aabb.min[1] = obb.position[1] - extents[1]
    aabb.min[2] = obb.position[2] - extents[2]
    aabb.min[3] = obb.position[3] - extents[3]
    aabb.max[1] = obb.position[1] + extents[1]
    aabb.max[2] = obb.position[2] + extents[2]
    aabb.max[3] = obb.position[3] + extents[3]
    return aabb
end

-- check if two models have intersecting AABBs
-- other argument is another model
--
-- sources:
--     https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection
function collisions:isIntersectionAABB(other)
    -- cache these references
    local a_min = self.aabb.min
    local a_max = self.aabb.max
    local b_min = other.aabb.min
    local b_max = other.aabb.max

    -- make shorter variable names for translation
    local a_1 = self.translation.x
    local a_2 = self.translation.y
    local a_3 = self.translation.z
    local b_1 = other.translation.x
    local b_2 = other.translation.y
    local b_3 = other.translation.z

    -- do the calculation
    local x = a_min[1] + a_1 <= b_max[1] + b_1 and a_max[1] + a_1 >= b_min[1] + b_1
    local y = a_min[2] + a_2 <= b_max[2] + b_2 and a_max[2] + a_2 >= b_min[2] + b_2
    local z = a_min[3] + a_3 <= b_max[3] + b_3 and a_max[3] + a_3 >= b_min[3] + b_3
    return x and y and z
end

-- check if a given point is inside the model's AABB
function collisions:isPointInsideAABB(x,y,z)
    local min = self.aabb.min
    local max = self.aabb.max

    local in_x = x >= min[1]*self.scale[1] + self.translation[1] and x <= max[1]*self.scale[1] + self.translation[1]
    local in_y = y >= min[2]*self.scale[2] + self.translation[2] and y <= max[2]*self.scale[2] + self.translation[2]
    local in_z = z >= min[3]*self.scale[3] + self.translation[3] and z <= max[3]*self.scale[3] + self.translation[3]

    return in_x and in_y and in_z
end


function collisions:characterVsAABB(other)
    -- cache these references
    local a_min = self.aabb.min
    local a_max = self.aabb.max
    local b_min = other.aabb.min
    local b_max = other.aabb.max

    -- make shorter variable names for translation
    local a_1 = self.translation.x
    local a_2 = self.translation.y
    local a_3 = self.translation.z
    local b_1 = 0--other.translation.x
    local b_2 = 0--other.translation.y
    local b_3 = 0--other.translation.z

    -- do the calculation
    local x = a_min[1] + a_1 <= b_max[1] + b_1 and a_max[1] + a_1 >= b_min[1] + b_1
    local y = a_min[2] + a_2 <= b_max[2] + b_2 and a_max[2] + a_2 >= b_min[2] + b_2
    local z = a_min[3] + a_3 <= b_max[3] + b_3 and a_max[3] + a_3 >= b_min[3] + b_3
    return x and y and z
end

-- check if a given point is inside the model's AABB
function collisions:isPointInsideAABB(x,y,z)
    local min = self.aabb.min
    local max = self.aabb.max

    local in_x = x >= min[1]*self.scale[1] + self.translation[1] and x <= max[1]*self.scale[1] + self.translation[1]
    local in_y = y >= min[2]*self.scale[2] + self.translation[2] and y <= max[2]*self.scale[2] + self.translation[2]
    local in_z = z >= min[3]*self.scale[3] + self.translation[3] and z <= max[3]*self.scale[3] + self.translation[3]

    return in_x and in_y and in_z
end

-- returns the distance from the point given to the origin of the model
function collisions:getDistanceFrom(x,y,z)
    return math.sqrt((x - self.translation[1])^2 + (y - self.translation[2])^2 + (z - self.translation[3])^2)
end

-- AABB - ray intersection
-- based off of ray - AABB intersection from excessive's CPML library
--
-- sources:
--     https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--     http://gamedev.stackexchange.com/a/18459
function collisions:rayIntersectionAABB(src_1, src_2, src_3, dir_1, dir_2, dir_3)
    local dir_1, dir_2, dir_3 = vectorNormalize(dir_1, dir_2, dir_3)

	local t1 = (self.aabb.min[1] + self.translation.x - src_1) / dir_1
	local t2 = (self.aabb.max[1] + self.translation.x - src_1) / dir_1
	local t3 = (self.aabb.min[2] + self.translation.y - src_2) / dir_2
	local t4 = (self.aabb.max[2] + self.translation.y - src_2) / dir_2
	local t5 = (self.aabb.min[3] + self.translation.z - src_3) / dir_3
	local t6 = (self.aabb.max[3] + self.translation.z - src_3) / dir_3

    local min = math.min
    local max = math.max
	local tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6))
	local tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6))

	-- ray is intersecting AABB, but whole AABB is behind us
	if tmax < 0 then
		return false
	end

	-- ray does not intersect AABB
	if tmin > tmax then
		return false
	end

    -- return distance and the collision coordinates
    local where_1 = src_1 + dir_1 * tmin
    local where_2 = src_2 + dir_2 * tmin
    local where_3 = src_3 + dir_3 * tmin
	return tmin, where_1, where_2, where_3
end


----------------------------------------------------------------------------------------------------
-- additional stuff, modified by PIGIC
----------------------------------------------------------------------------------------------------
function collisions.ray_sphere(src_x, src_y, src_z, dir_x, dir_y, dir_z, sphere_x, sphere_y, sphere_z, sphere_r)
	local offset_x = src_x - sphere_x
	local offset_y = src_y - sphere_y
	local offset_z = src_z - sphere_z
    
    local b = vectorDotProduct(offset_x, offset_y, offset_z, dir_x, dir_y, dir_z)
    local c = vectorDotProduct(offset_x, offset_y, offset_z, offset_x, offset_y, offset_z) - sphere_r * sphere_r

	-- ray's position outside sphere (c > 0)
	-- ray's direction pointing away from sphere (b > 0)
	if c > 0 and b > 0 then
		return false
	end

	local discr = b * b - c

	-- negative discriminant
	if discr < 0 then
		return false
	end

	-- Clamp t to 0
	local t = -b - math.sqrt(discr)
	t = t < 0 and 0 or t

	-- Return collision point and distance from ray origin
    return
        src_x + dir_x * t,
        src_y + dir_y * t,
        src_z + dir_z * t,
        t
end

local function translate(vertex, t)
    vertex[1] = vertex[1] + t.x
    vertex[2] = vertex[2] + t.y
    vertex[3] = vertex[3] + t.z
end

local function scale(vertex, s)
    vertex[1] = vertex[1] * s.x
    vertex[2] = vertex[2] * s.y
    vertex[3] = vertex[3] * s.z
end

function rotate_axis_angle(vertex, angle, axis)
    local ax, ay, az = axis:normalize():unpack()
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    local one_minus_cos = 1 - cosA

    -- Compute the rotation matrix components
    local r11 = cosA + ax * ax * one_minus_cos
    local r12 = ax * ay * one_minus_cos - az * sinA
    local r13 = ax * az * one_minus_cos + ay * sinA

    local r21 = ay * ax * one_minus_cos + az * sinA
    local r22 = cosA + ay * ay * one_minus_cos
    local r23 = ay * az * one_minus_cos - ax * sinA

    local r31 = az * ax * one_minus_cos - ay * sinA
    local r32 = az * ay * one_minus_cos + ax * sinA
    local r33 = cosA + az * az * one_minus_cos

    -- Apply rotation to the vertex
    local x, y, z = vertex[1], vertex[2], vertex[3]
    vertex[1] = r11 * x + r12 * y + r13 * z
    vertex[2] = r21 * x + r22 * y + r23 * z
    vertex[3] = r31 * x + r32 * y + r33 * z
end


function collisions:load_collider()
    local collider = table.copy(self.model.collider)
    for _, v in ipairs(collider) do
        -- scale
            -- pass, skip scale for now
        rotate_axis_angle(v, self.rotation.angle, self.rotation.axis)        
        translate(v, self.translation)
    end
    
    return collider
end



local function rotate_vector(vx, vy, vz, axis_x, axis_y, axis_z, angle)
    local cos_theta = math.cos(angle)
    local sin_theta = math.sin(angle)
    local dot = vectorDotProduct(axis_x, axis_y, axis_z, vx, vy, vz)
    local cross = vectorCrossProduct(axis_x, axis_y, axis_z, vx, vy, vz)

    local rotated_x = vx * cos_theta + cross * sin_theta + axis_x * dot * (1 - cos_theta)
    local rotated_y = vy * cos_theta + cross * sin_theta + axis_y * dot * (1 - cos_theta)
    local rotated_z = vz * cos_theta + cross * sin_theta + axis_z * dot * (1 - cos_theta)
    return rotated_x, rotated_y, rotated_z
end


function collisions:load_obb(data)
    local d = data['COLLIDER']
    local collider = {}
    -- collider.forward = vec3(d.rotation.forward.x, d.rotation.forward.y, d.rotation.forward.z):normalize()
    -- collider.right = vec3(d.rotation.right.x, d.rotation.right.y, d.rotation.right.z):normalize()
    -- collider.up = vec3(d.rotation.up.x, d.rotation.up.y, d.rotation.up.z):normalize()
    -- collider.position = vec3(d.position.x, d.position.y, d.position.z)
    -- collider.half_extents = vec3(d.half_extents.x, d.half_extents.y, d.half_extents.z)

    -- collider.forward = rotate_vector(collider.forward, self.rotation.angle, self.rotation.axis):normalize()
    -- collider.right = rotate_vector(collider.right, self.rotation.angle, self.rotation.axis):normalize()
    -- collider.up = rotate_vector(collider.up, self.rotation.angle, self.rotation.axis):normalize()
    -- collider.position:add(self.translation)

    local axis = self.rotation.axis
    local angle = self.rotation.angle
    local forward = d.rotation.forward
    local right = d.rotation.right
    local up = d.rotation.up
    
    local fx, fy, fz = vectorNormalize(forward[1], forward[2], forward[3])
    local rx, ry, rz = vectorNormalize(right[1], right[2], right[3])
    local ux, uy, uz = vectorNormalize(up[1], up[2], up[3])
    
    collider.forward = rotate_vector(fx, fy, fz, axis.x, axis.y, axis.z, angle)
    collider.right = rotate_vector(rx, ry, rz, axis.x, axis.y, axis.z, angle)
    collider.up = rotate_vector(ux, uy, uz, axis.x, axis.y, axis.z, angle)
    collider.center = {d.center[1] + self.translation.x, d.center[2] + self.translation.y, d.center[3] + self.translation.z}
    collider.half_extents = d.half_extents
    
    return collider
end


function collisions:draw_aabb_from_obb()
    local min = self.aabb.min
    local max = self.aabb.max

    local x1, y1, z1 = min[1], min[2], min[3]
    local x2, y2, z2 = max[1], max[2], max[3]

    local corners = {
        {x1, y1, z1}, -- 1
        {x2, y1, z1}, -- 2
        {x2, y2, z1}, -- 3
        {x1, y2, z1}, -- 4
        {x1, y1, z2}, -- 5
        {x2, y1, z2}, -- 6
        {x2, y2, z2}, -- 7
        {x1, y2, z2}, -- 8
    }

    local edges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- bottom
        {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- top
        {1, 5}, {2, 6}, {3, 7}, {4, 8}, -- sides
    }

    for _, edge in ipairs(edges) do
        local a = corners[edge[1]]
        local b = corners[edge[2]]
        pass.line(vec3(a[1], a[2], a[3]), vec3(b[1], b[2], b[3]), .1)
    end
end

function collisions:draw_collider()
    for i = 1, #self.collider-1 do
        local a = self.collider[i]
        local b = self.collider[i+1]
        pass.line(vec3(a[1], a[2], a[3]), vec3(b[1], b[2], b[3]), .05)
    end
end

local mathmax = math.max
local mathmin = math.min

-- Vector math helpers (assumes you have vec3 operations like dot, sub, etc.)
local function clamp(x, min, max)
    return mathmax(min, mathmin(max, x))
end

-- local function inverseTransformPoint(box, point)
--     local localPos = point - box.center
--     return vec3(
--         localPos:dot(box.right),
--         localPos:dot(box.up),
--         localPos:dot(box.forward)
--     )
-- end



-- local function transformPoint(box, localPoint)
--     return box.center +
--         box.right * localPoint.x +
--         box.up * localPoint.y +
--         box.forward * localPoint.z
-- end

-- local function transformDirection(box, localDir)
--     return (box.right * localDir.x +
--             box.up * localDir.y +
--             box.forward * localDir.z):normalize()
-- end


function collisions.sphereOBBCollision(obb, sphere_center, sphere_radius)
    -- Transform sphere center to OBB's local space
    local localSphereCenter = inverseTransformPoint(obb, sphere_center)

    -- Find closest point on OBB to sphere center
    local closest = vec3(
        clamp(localSphereCenter.x, -obb.halfExtents.x, obb.halfExtents.x),
        clamp(localSphereCenter.y, -obb.halfExtents.y, obb.halfExtents.y),
        clamp(localSphereCenter.z, -obb.halfExtents.z, obb.halfExtents.z)
    )

    local offset = localSphereCenter - closest
    local offsetLen = offset:len()

    -- Case 1: Sphere is outside and intersecting
    if offsetLen > 0 and offsetLen < sphere_radius then
        local collisionNormal = transformDirection(obb, offset:normalize())
        local collisionPoint = transformPoint(obb, closest)
        -- local penetrationDepth = sphere_radius - offsetLen
        local penetrationDepth = offsetLen
        
        return penetrationDepth,
               collisionPoint.x, collisionPoint.y, collisionPoint.z,
               collisionNormal.x, collisionNormal.y, collisionNormal.z

    -- Case 2: Sphere center is inside OBB
    elseif offsetLen == 0 then
        -- Find closest face
        local distances = {
            x = obb.halfExtents.x - math.abs(localSphereCenter.x),
            y = obb.halfExtents.y - math.abs(localSphereCenter.y),
            z = obb.halfExtents.z - math.abs(localSphereCenter.z)
        }

        -- Determine closest axis
        local axis, sign = "x", 1
        local minDist = distances.x
        if distances.y < minDist then axis, sign, minDist = "y", math.sign(localSphereCenter.y), distances.y end
        if distances.z < minDist then axis, sign, minDist = "z", math.sign(localSphereCenter.z), distances.z end

        -- Create normal vector
        local normalLocal = vec3(0, 0, 0)
        normalLocal[axis] = sign
        -- No need to normalize as it's already unit length for axis-aligned cases

        local collisionPointLocal = vec3(
            closest.x,
            closest.y,
            closest.z
        )
        collisionPointLocal[axis] = sign * obb.halfExtents[axis]  -- Push to surface

        local collisionNormal = transformDirection(obb, normalLocal)
        local collisionPoint = transformPoint(obb, collisionPointLocal)
        local penetrationDepth = sphere_radius + minDist
        
        return penetrationDepth,
               collisionPoint.x, collisionPoint.y, collisionPoint.z,
               collisionNormal.x, collisionNormal.y, collisionNormal.z
    end

    -- No collision
    return nil
end





-- box center, box right, box up, box forward, point
local function inverse_transform_point(bx,by,bz, brx,bry,brz, bux,buy,buz, bfx,bfy,bfz, px,py,pz)
    local local_pos_x = px - bx
    local local_pos_y = py - by
    local local_pos_z = pz - bz

    local dot_x = vectorDotProduct(local_pos_x, local_pos_y, local_pos_z, brx, bry, brz)
    local dot_y = vectorDotProduct(local_pos_x, local_pos_y, local_pos_z, bux, buy, buz)
    local dot_z = vectorDotProduct(local_pos_x, local_pos_y, local_pos_z, bfx, bfy, bfz)

    return dot_x, dot_y, dot_z
end


local function transform_point(bx,by,bz, brx,bry,brz, bux,buy,buz, bfx,bfy,bfz, px,py,pz)
    local tx = bx + brx * px + bux * py + bfx * pz
    local ty = by + bry * px + buy * py + bfy * pz
    local tz = bz + brz * px + buz * py + bfz * pz

    return tx, ty, tz
end


local function transform_direction(brx,bry,brz, bux,buy,buz, bfx,bfy,bfz, px,py,pz)
    local x = brx * px + bux * py + bfx * pz
    local y = bry * px + buy * py + bfy * pz
    local z = brz * px + buz * py + bfz * pz
    
    return vectorNormalize(x, y, z)
end


function collisions.sphere_obb(obb, px, py, pz, radius)
    -- localize data like a 'real' programmer
    
    -- obb center
    local bx = obb.center[1]
    local by = obb.center[2]
    local bz = obb.center[3]
    -- obb right
    local brx = obb.right[1]
    local bry = obb.right[2]
    local brz = obb.right[3]
    -- obb up
    local bux = obb.up[1]
    local buy = obb.up[2]
    local buz = obb.up[3]
    -- obb forward
    local bfx = obb.forward[1]
    local bfy = obb.forward[2]
    local bfz = obb.forward[3]
    -- obb half extents
    local bhx = obb.half_extents[1]
    local bhy = obb.half_extents[2]
    local bhz = obb.half_extents[3]

    -- Transform sphere center to OBB's local space
    local
        local_sphere_center_x,
        local_sphere_center_y,
        local_sphere_center_z = inverse_transform_point(bx,by,bz, brx,bry,brz, bux,buy,buz, bfx,bfy,bfz, px,py,pz)

    local closest_x = clamp(local_sphere_center_x, -bhx, bhx)
    local closest_y = clamp(local_sphere_center_y, -bhy, bhy)
    local closest_z = clamp(local_sphere_center_z, -bhz, bhz)

    local offset_x = local_sphere_center_x - closest_x
    local offset_y = local_sphere_center_y - closest_y
    local offset_z = local_sphere_center_z - closest_z

    local offset_len = vectorMagnitude(offset_x, offset_y, offset_z)

    -- Case 1: Sphere is outside and intersecting
    if offset_len > 0 and offset_len < radius then
        
    end
end


return collisions
