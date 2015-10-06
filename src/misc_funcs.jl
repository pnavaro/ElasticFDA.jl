function approx(xd, yd, xi)
    nd = length(xd);
    ni = length(xi);

    yi = zeros(ni);
    for i in 1:ni
        if (xi[i] <= xd[1])
            t = (xi[i]-xd[1]) / (xd[2] - xd[1]);
            yi[i] = (1.0 - t) * yd[1] + t * yd[2];
        elseif (xd[nd] <= xi[i])
            t = (xi[i] - xd[nd-1]) / (xd[nd] - xd[nd-1]);
            yi[i] = (1.0 - t) * yd[nd-1] + t * yd[nd];
        else
            for k in 2:nd
                if (xd[k-1] <= xi[i] && xi[i] <= xd[k])
                    t = (xi[i] - xd[k-1]) / (xd[k] - xd[k-1]);
                    yi[i] = (1.0 - t) * yd[k-1] + t * yd[k];
                    break
                end
            end
        end
    end

    return yi
end


function trapz(x::Array{Float64, 1}, y::Array{Float64}, dim::Int64=1)
    perm = [dim:max(ndims(y),dim), 1:dim-1];
    y = permutedims(y, perm);
    if ndims(y) == 1
        m = 1;
    else
        m = size(y,1);
    end

    if m == 1
        M = length(y);
        out = sum(diff(x).*(y[1:M-1] + y[2:M])/2.);
    else
        out = diff(x).' * (y[1:m-1,:] + y[2:m,:])/2.;
        siz = size(y); siz = collect(siz); siz[1] = 1;
        out = reshape(out, tuple(siz...));
        out = ipermutedims(out, perm);
        out = squeeze(out,length(perm));
    end

    return out
end


function cumtrapz(x::Array{Float64, 1}, y::Array{Float64}, dim::Int64=1)
    perm = [dim:max(length(size(y)),dim); 1:dim-1];
    y = permutedims(y, perm);
    if ndims(y) == 1
        n = 1;
        m = length(y);
    else
        m, n = size(y);
    end

    if n == 1
        dt = diff(x)/2.0;
        z = [0; cumsum(dt.*(y[1:(m-1)] + y[2:m]))];
    else
        dt = repmat(diff(x)/2.0,1,n);
        z = [zeros(1,n); cumsum(dt.*(y[1:(m-1), :] + y[2:m, :]),1)];
        z = ipermutedims(z, perm);
    end

    return z
end


function cumtrapzmid(x, y, c)
    a = length(x);
    mid = round(a/2);

    # case < mid
    fn = zeros(a);
    tmpx = x[(mid-1):-1:1];
    tmpy = y[(mid-1):-1:1];
    tmp = c + cumtrapz(tmpx, tmpy);
    fn[1:(mid-1)] = reverse(tmp);

    # case >= mid
    fn[mid:a] = c + cumtrapz(x[mid:a],y[mid:a]);

    return fn

end


function mvnrand(mu, C, n)
    tmp = cholfact(C, :U, pivot=true);
    R = tmp[:U];
    R = R[:, tmp.piv];
    retval = randn(n, size(R,1)) * R;
    retval += transpose(repmat(mu, 1, n));
    return transpose(retval)
end


function interp1_flat(x,y,xx)
    flat = find(diff(x).==0);
    n = length(flat);

    if n==0
        tmp = InterpIrregular(x,y,BCnil,InterpLinear);
        yy = tmp[xx];
    else
        yy = zeros(size(xx));
        i1 = 1;
        if flat[1] == 1
            i2 = 1;
            j = xx.==x[i2];
            yy[j] = minimum(y[i2:i2+1]);
        else
            i2 = flat[1];
            j = (xx.>=x[i1]) & (xx.<=x[i2]);
            tmp = InterpIrregular(x[i1:i2],y[i1:i2],BCnil,InterpLinear);
            yy[j] = tmp[xx[j]];
            i1 = copy(i2);
        end
        for k = 2:n
            i2 = flat[k];
            if i2 > i1+1
                j = (xx.>=x[i1]) & (xx.<=x[i2]);
                tmp = InterpIrregular(x[i1+1:i2],y[i1+1:i2],BCnil,InterpLinear);
                yy[j] = tmp[xx[j]];
            end
            j = xx.==x[i2];
            yy[j] = minimum(y[i2:i2+1]);
            i1 = copy(i2);
        end
        i2 = length(x);
        j = (xx.>=x[i1]) & (xx.<=x[i2]);
        if i1+1 == i2
            yy[j] = y[i2];
        else
            tmp = InterpIrregular(x[i1+1:i2],y[i1+1:i2],BCnil,InterpLinear);
            yy[j] = tmp[xx[j]];
        end
    end

    return yy
end

