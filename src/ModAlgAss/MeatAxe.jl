export submodules, minimal_submodules, maximal_submodules, composition_series,
       composition_factors, meataxe

################################################################################
#
#  Tools for MeatAxe
#
################################################################################

#
# Given a matrix $M$ in echelon form and a vector, it returns
# the vector reduced with respect to $M$
#
function cleanvect(M::T, v::T) where {T}
  @assert nrows(v)==1
  w=deepcopy(v)
  if iszero(v)
    return w  
  end
  for i=1:nrows(M)
    if iszero_row(M,i)
      continue
    end
    ind=1
    while iszero(M[i,ind])
      ind+=1
    end
    if iszero(w[1,ind])
      continue
    end
    mult=divexact(w[1,ind], M[i,ind])
    w[1,ind] = parent(M[1,1])(0)
    for k=ind+1:ncols(M)
      w[1,k]-= mult*M[i,k]
    end      
  end
  return w

end

#
#  Given a matrix C containing the coordinates of vectors v_1,dots, v_k 
#  in echelon form, the function computes a basis for the submodule they generate
# 

function closure(C::T, G::Array{T,1}) where {T}
  rref!(C)
  i=1
  while i <= nrows(C)
    w=view(C, i:i, 1:ncols(C))
    for j=1:length(G)
      res=cleanvect(C,w*G[j])
      if !iszero(res)
        C = vcat(C,res)  
        if nrows(C)==ncols(C)
          i=ncols(C)+1
          break
        end
      end 
    end  
    i+=1
  end
  r = rref!(C)
  if r != nrows(C)
    C = sub(C, 1:r, 1:ncols(C))
  end
  return C
end

#
#  Given a matrix C containing the coordinates of vectors v_1,dots, v_k,
#  the function computes a basis for the submodule they generate
# 

function spinning(C::T,G::Array{T,1}) where {T}

  B=deepcopy(C)
  X=rref(C)[2]
  i=1
  while i != nrows(B)+1
    for j=1:length(G)
      el= view(B, i:i, 1:ncols(B)) * G[j]
      res= cleanvect(X,el)
      if !iszero(res)
        X=vcat(X,res)
        rref!(X)
        B=vcat(B,el)
        if nrows(B)==ncols(B)
          return B
        end
      end
    end  
    i+=1
  end
  return B
  
end

#
#  Function to obtain the action of G on the quotient and on the submodule
#

function clean_and_quotient(M::T,N::T, pivotindex::Set{Int}) where {T}

  coeff=zero_matrix(parent(M[1,1]),nrows(N),nrows(M))
  for i=1:nrows(N)
    for j=1:nrows(M)
      if iszero_row(M,j)
        continue
      end
      ind=1
      while iszero(M[j,ind])
        ind+=1
      end
      coeff[i,j]=divexact(N[i,ind], M[j,ind])
      for s=1:ncols(N)
        N[i,s]-=coeff[i,j]*M[j,s]
      end
    end
  end 
  vec= zero_matrix(parent(M[1,1]),nrows(N),ncols(M)-length(pivotindex))
  for i=1:nrows(N)  
    pos=0
    for s=1:ncols(M)
      if !(s in pivotindex)
        pos+=1
        vec[i,pos]=N[i,s]
      end 
    end
  end
  return coeff, vec
end


#  Restriction of the action to the submodule generated by C and the quotient

function __split(C::T, G::Vector{T}) where {T <: MatElem}
# I am assuming that C defines an submodule
  equot=Vector{T}(undef, length(G))
  esub=Vector{T}(undef, length(G))
  pivotindex=Set{Int}()
  for i = 1:nrows(C)
    if iszero_row(C,i)
      continue
    end
    ind = 1
    while iszero(C[i, ind])
      ind += 1
    end
    push!(pivotindex, ind)   
  end
  for a = 1:length(G)
    subm, vec=clean_and_quotient(C, C*G[a], pivotindex)
    esub[a] = subm
    s = zero_matrix(base_ring(C),ncols(G[1]) - length(pivotindex), ncols(G[1]) - length(pivotindex))
    pos = 0
    for i= 1:nrows(G[1])
      if !(i in pivotindex)
        m, vec= clean_and_quotient(C, sub(G[a], i:i, 1:nrows(G[1])), pivotindex)
        for j=1:ncols(vec)
          s[i - pos,j] = vec[1, j]
        end
      else 
        pos += 1
      end
    end
    equot[a] = s
  end
  return ModAlgAss(esub), ModAlgAss(equot), pivotindex
end

#  Restriction of the action to the submodule generated by C
function _actsub(C::T, G::Vector{T}) where {T <: MatElem}
  esub = Vector{T}(undef, length(G))
  pivotindex = Set{Int}()
  for i=1:nrows(C)
    ind = 1
    while iszero(C[i, ind])
      ind += 1
    end
    push!(pivotindex, ind)   
  end
  for a=1:length(G)
    subm, vec = clean_and_quotient(C, C*G[a], pivotindex)
    esub[a] = subm
  end
  return ModAlgAss(esub)
  #return ModAlgAss(esub)
end

#  Restriction of the action to the quotient by the submodule generated by C
function _actquo(C::T,G::Vector{T}) where {T <: MatElem}
  equot = Vector{T}(undef, length(G))
  pivotindex = Set{Int}()
  for i=1:nrows(C)
    ind = 1
    while iszero(C[i,ind])
      ind += 1
    end
    push!(pivotindex,ind)   
  end
  for a=1:length(G)
    s = zero_matrix(base_ring(C), ncols(G[1]) - length(pivotindex), ncols(G[1]) - length(pivotindex))
    pos = 0
    for i=1:nrows(G[1])
      if !(i in pivotindex)
        m, vec = clean_and_quotient(C, sub(G[a],i:i,1:nrows(G[1])), pivotindex)
        for j=1:ncols(vec)
          s[i - pos, j]=vec[1, j]
        end
      else 
        pos += 1
      end
    end
    equot[a] = s
  end
  return ModAlgAss(equot), pivotindex
end

#
#  Function that determine if two modules are isomorphic, provided that the first is irreducible
#
function isisomorphic(M::ModAlgAss{S, T, V}, N::ModAlgAss{S, T, V}) where {S, T, V}
  @assert M.isirreducible == 1
  @assert base_ring(M) == base_ring(N)
  @assert length(M.action) == length(N.action)
  if dimension(M) != dimension(N)
    return false
  end

  if M.dimension==1
    return M.action==N.action
  end

  K = base_ring(M)
  Kx, x = PolynomialRing(K, "x", cached=false)
  
  if length(M.action) == 1
    f = charpoly(Kx, M.action[1])
    g = charpoly(Kx, N.action[1])
    if f==g
      return true
    else
      return false
    end
  end
  rel = _relations(M,N)
  return iszero(rel[N.dimension, N.dimension])

end

function _enum_el(K,v,dim)
  if dim == 0
    return [v]
  else 
    list=[]
    push!(v,K(0))
    for x in K 
      v[length(v)]=x
      push!(list,deepcopy(v))
    end
    list1=[]
    for x in list
      append!(list1,_enum_el(K,x, dim-1))
    end
    return list1
  end
end

function dual_space(M::ModAlgAss{S, T, V}) where {S, T, V}
  G = T[transpose(g) for g in M.action]
  return ModAlgAss(G)
end

function _subst(f::Nemo.PolyElem{T}, a::S) where {T <: Nemo.RingElement, S}
   #S = parent(a)
   n = degree(f)
   if n < 0
      return similar(a)#S()
   elseif n == 0
      return coeff(f, 0) * identity_matrix(base_ring(a), nrows(a))
   elseif n == 1
      return coeff(f, 0) * identity_matrix(base_ring(a), nrows(a)) + coeff(f, 1)*a
   end
   d1 = isqrt(n)
   d = div(n, d1)
   A = powers(a, d)
   s = coeff(f, d1*d)*A[1]
   for j = 1:min(n - d1*d, d - 1)
      c = coeff(f, d1*d + j)
      if !iszero(c)
         s += c*A[j + 1]
      end
   end
   for i = 1:d1
      s *= A[d + 1]
      s += coeff(f, (d1 - i)*d)*A[1]
      for j = 1:min(n - (d1 - i)*d, d - 1)
         c = coeff(f, (d1 - i)*d + j)
         if !iszero(c)
            s += c*A[j + 1]
         end
      end
   end
   return s
end

#################################################################
#
#  MeatAxe, Composition Factors and Composition Series
#
#################################################################

@doc Markdown.doc"""
***
    meataxe(M::ModAlgAss) -> Bool, MatElem

> Given module M, returns true if the module is irreducible (and the identity matrix) and false if the space is reducible, togheter with a basis of a submodule

"""
function meataxe(M::ModAlgAss{S, T, V}) where {S, T, V}

  K=base_ring(M)
  Kx,x=PolynomialRing( K,"x", cached=false)
  n=dimension(M)
  H = M.action
  if n == 1
    M.isirreducible = 1
    return true, identity_matrix(base_ring(H[1]), n)
  end
  
  
  G = deepcopy(H)
  filter!(x -> !iszero(x), G)

  if length(G) == 0
    return false, matrix(base_ring(H[1]), 1, n, [one(base_ring(H[1])) for i = 1:n])
  end

  if length(G)==1
    A = G[1]
    poly=charpoly(Kx,A)
    sq = factor_squarefree(poly)
    lf = factor(first(keys(sq.fac)))
    t = first(keys(lf.fac))
    if degree(t)==n
      M.isirreducible= 1
      return true, identity_matrix(base_ring(G[1]), n)
    else 
      N = _subst(t, A)
      null, kern = kernel(N, side = :left)
      B = closure(sub(kern,1:1, 1:n), G)
      return false, B
    end
  end
  
  #
  #  Adding generators to obtain randomness
  #


  Gt = T[transpose(x) for x in M.action]
  
  #for i=1:max(length(M.action),9)
  #  l1=rand(1:length(G))
  #  l2=rand(1:length(G))
  #  while l1 !=l2
  #    l2=rand(1:length(G))
  #  end
  #  push!(G, G[l1]*G[l2])
  #end
  
  cnt = 0
  while true
    cnt += 1
    if cnt > 1000
      error("Too many attempts")
    end
    # At every step, we add a generator to the group.
    new_gen = G[rand(1:length(G))]*G[rand(1:length(G))]
    while iszero(new_gen)
      new_gen = G[rand(1:length(G))]*G[rand(1:length(G))]
    end
    push!(G, new_gen)
    
    #
    # Choose a random combination of the generators of G
    #
    A = zero_matrix(K, n, n)
    for i=1:length(G)
      A += rand(K)*G[i]
    end
 
    #
    # Compute the characteristic polynomial and, for irreducible factor f, try the Norton test
    # 
    poly=charpoly(Kx,A)
    sqfpart = keys(factor_squarefree(poly).fac)
    for el in sqfpart
      sq = el
      i=1
      while !isone(sq)
        f = gcd(powmod(x, order(K)^i, sq)-x,sq)
        sq = divexact(sq, f)
        lf=factor(f)
        for t in keys(lf.fac)
          N = _subst(t, A)
          a, kern = kernel(N, side = :left)
          @assert a > 0
          #  Norton test  
          B = closure(sub(kern, 1:1, 1:n), M.action)
          if nrows(B) != n
            M.isirreducible= 2
            return false, B
          end
          aa, kernt = kernel(transpose(N), side = :left)
          @assert aa == a
          Bt = closure(sub(kernt, 1:1, 1:n), Gt)
          if nrows(Bt) != n
            aa, Btnu = kernel(Bt)
            subst = transpose(Btnu)
            #@assert nrows(subst)==nrows(closure(subst,G))
            M.isirreducible = 2
            return false, subst
          end
          if degree(t) == a
            # f is a good factor, irreducibility!
            M.isirreducible = 1
            return true, identity_matrix(base_ring(G[1]), n)
          end
        end
        i+=1
      end
    end
  end
end

@doc Markdown.doc"""
***
    composition_series(M::ModAlgAss) -> Array{MatElem,1}

> Given a Fq[G]-module M, it returns a composition series for M, i.e. a sequence of submodules such that the quotient of two consecutive element is irreducible.

"""
function composition_series(M::ModAlgAss{S, T, V}) where {S, T, V}

  if M.isirreducible == 1 || M.dimension == 1
    return [identity_matrix(base_ring(M.action[1]), M.dimension)]
  end

  bool, C = meataxe(M)
  #
  #  If the module is irreducible, we return a basis of the space
  #
  if bool == true
    return [identity_matrix(base_ring(M.action[1]), M.dimension)]
  end
  #
  #  The module is reducible, so we call the algorithm on the quotient and on the subgroup
  #
  G=M.action
  K=M.base_ring
  
  rref!(C)
  
  esub,equot,pivotindex=__split(C,G)
  sub_list = composition_series(esub)
  quot_list = composition_series(equot)
  #
  #  Now, we have to write the submodules of the quotient and of the submodule in terms of our basis
  #
  list=Vector{T}(undef, length(sub_list)+length(quot_list))
  for i=1:length(sub_list)
    list[i]=sub_list[i]*C
  end
  for z=1:length(quot_list)
    s=zero_matrix(K,nrows(quot_list[z]), ncols(C))
    for i=1:nrows(quot_list[z])
      pos=0
      for j=1:ncols(C)
        if j in pivotindex
          pos+=1
        else
          s[i,j]=quot_list[z][i,j-pos]
        end
      end
    end
    list[length(sub_list)+z]=vcat(C,s)
  end
  return list
end

@doc Markdown.doc"""
***
    composition_factors(M::ModAlgAss)

> Given a Fq[G]-module M, it returns, up to isomorphism, the composition factors of M with their multiplicity,
> i.e. the isomorphism classes of modules appearing in a composition series of M

"""
function composition_factors(M::ModAlgAss{S, T, V}; dimension::Int=-1) where {S, T, V}

  if M.isirreducible == 1 || M.dimension == 1
    if dimension != -1 
      if M.dimension == dimension
        return Tuple{ModAlgAss{S, T, V}, Int}[(M,1)]
      else
        return Tuple{ModAlgAss{S, T, V}, Int}[]
      end
    else
      return Tuple{ModAlgAss{S, T, V}, Int}[(M,1)]
    end
  end 
 
  K=M.base_ring
  bool, C = meataxe(M)
  #
  #  If the module is irreducible, we just return a basis of the space
  #
  if bool
    if dimension!= -1 
      if M.dimension==dimension
        return Tuple{ModAlgAss{S, T}, Int}[(M,1)]
      else
        return Tuple{ModAlgAss{S, T}, Int}[]
      end
    else
      return Tuple{ModAlgAss{S, T}, Int}[(M,1)]
    end
  end
  G=M.action
  #
  #  The module is reducible, so we call the algorithm on the quotient and on the subgroup
  #
  
  rref!(C)
  
  sub,quot,pivotindex=__split(C,G)
  sub_list = composition_factors(sub)
  quot_list = composition_factors(quot)
  #
  #  Now, we check if the factors are isomorphic
  #
  for i=1:length(sub_list)
    for j=1:length(quot_list)
      if isisomorphic(sub_list[i][1], quot_list[j][1])
        sub_list[i]=(sub_list[i][1], sub_list[i][2]+quot_list[j][2])
        deleteat!(quot_list,j)
        break
      end    
    end
  end
  return append!(sub_list, quot_list) 

end

function _relations(M::ModAlgAss{S, T, V}, N::ModAlgAss{S, T, V}) where {S, T, V}
  @assert M.isirreducible == 1
  G=M.action
  H=N.action
  K=base_ring(M)
  n=dimension(M)
  
  sys=zero_matrix(K,2*dimension(N),dimension(N))
  matrices=T[]
  first=true
  B=zero_matrix(K,1,dimension(M))
  B[1,1]=K(1)
  X=B
  push!(matrices, identity_matrix(base_ring(B), dimension(N)))
  i=1
  while i<=nrows(B)
    w=sub(B, i:i, 1:n)
    for j=1:length(G)
      v=w*G[j]
      res=cleanvect(X,v)
      if !iszero(res)
        X=rref(vcat(X,v))[2]
        B=vcat(B,v)
        push!(matrices, matrices[i]*H[j])
      else
        fl, x = can_solve(B, v, side = :left)
        @assert fl
        A=sum([x[1,q]*matrices[q] for q=1:ncols(x)])
        A=A-(matrices[i]*H[j])
        if first
          for s=1:N.dimension
            for t=1:N.dimension
              sys[s,t]=A[t,s]
            end
          end
          first=false
        else
          for s=1:N.dimension
            for t=1:N.dimension
              sys[N.dimension+s,t]=A[t,s]
            end
          end
        end
        rref!(sys)
      end
    end
    if sys[N.dimension,N.dimension]!=0
      break
    end
    i=i+1
  end
  return view(sys, 1:N.dimension, 1:N.dimension)
end

function _irrsubs(M::ModAlgAss{S, T}, N::ModAlgAss{S, T}) where {S, T}

  @assert M.isirreducible == 1
  
  K=M.base_ring
  rel=_relations(M,N)
  if rel[N.dimension, N.dimension]!=0
    return T[]
  end
  a,kern = nullspace(rel)
  # TODO: Remove this once fixed.
  if !(kern isa T)
    a, kern = kern, a
  end
  kern = transpose(kern)
  if a == 1
    return T[closure(kern, N.action)]
  end  
  vects=T[sub(kern, i:i, 1:N.dimension) for i=1:a]

  #
  #  Try all the possibilities. (A recursive approach? I don't know if it is a smart idea...)
  #  Notice that we eliminate lots of candidates considering the action of the group on the homomorphisms space
  #
  candidate_comb=append!(_enum_el(K,[K(0)], length(vects)-1),_enum_el(K,[K(1)],length(vects)-1))
  deleteat!(candidate_comb,1)
  list=Array{T,1}(undef, length(candidate_comb))
  for j=1:length(candidate_comb)
    list[j] = sum([candidate_comb[j][i]*vects[i] for i=1:length(vects)])
  end
  final_list=T[]
  push!(final_list, closure(list[1], N.action))
  for i = 2:length(list)
    reduce=true
    for j=1:length(final_list)      
      w=cleanvect(final_list[j],list[i])
      if iszero(w)
        reduce=false
        break
      end
    end  
    if reduce
      push!(final_list, closure(list[i],N.action))
    end
  end
  return final_list

end

@doc Markdown.doc"""
***
    minimal_submodules(M::ModAlgAss)

> Given a Fq[G]-module M, it returns all the minimal submodules of M

"""
function minimal_submodules(M::ModAlgAss{S, T, V}, dim::Int=M.dimension+1, lf = Tuple{ModAlgAss{S, T, V}, Int}[]) where {S, T, V}
  
  K = M.base_ring
  n = M.dimension
  
  if isone(M.isirreducible)
    if dim >= n
      return T[identity_matrix(K, n)]
    else
      return T[]
    end
  end

  list = T[]
  if isempty(lf)
    lf = composition_factors(M)
  end
  if isone(length(lf)) && isone(lf[1][2])
    return T[identity_matrix(K, n)]
  end
  if dim!=n+1
    lf=[x for x in lf if x[1].dimension==dim]
  end
  if isempty(lf)
    return list
  end
  for x in lf
    append!(list, Hecke._irrsubs(x[1], M)) 
  end
  return list
end


@doc Markdown.doc"""
***
    maximal_submodules(M::ModAlgAss)

> Given a $G$-module $M$, it returns all the maximal submodules of M

"""

function maximal_submodules(M::ModAlgAss{S, T, V}, index::Int=M.dimension, lf = Tuple{ModAlgAss{S, T, V}, Int}[]) where {S, T, V}

  M_dual = dual_space(M)
  minlist = minimal_submodules(M_dual, index+1, lf)
  maxlist = Array{T, 1}(undef, length(minlist))
  for j=1:length(minlist)
    maxlist[j]=transpose(nullspace(minlist[j])[2])
  end
  return maxlist

end

@doc Markdown.doc"""
***
    submodules(M::ModAlgAss)

> Given a $G$-module $M$, it returns all the submodules of M

"""

function submodules(M::ModAlgAss{S, T, V}) where {S, T, V}

  K=M.base_ring
  list = T[]
  if M.dimension == 1
    return [zero_matrix(K, 1, 1), identity_matrix(K, 1)]
  end
  lf=composition_factors(M)
  minlist = minimal_submodules(M, M.dimension+1, lf)
  for x in minlist
    rref!(x)
    N, pivotindex =_actquo(x,M.action)
    ls=submodules(N)
    for a in ls
      s=zero_matrix(K,nrows(a), M.dimension)
      for t=1:nrows(a)
        pos=0
        for j=1:M.dimension
          if j in pivotindex
            pos+=1
          else
            s[t,j]=a[t,j-pos]
          end
        end
      end
      push!(list,vcat(x,s))
    end
  end
  for x in list
    rref!(x)
  end
  i=2
  while i<length(list)
    j=i+1
    while j<=length(list)
      if nrows(list[j])!=nrows(list[i])
        j+=1
      elseif list[j]==list[i]
        deleteat!(list, j)
      else 
        j+=1
      end
    end
    i+=1
  end
  append!(list,minlist)
  push!(list, zero_matrix(K, 0, M.dimension))
  push!(list, identity_matrix(K, M.dimension))
  return list
  
end

@doc Markdown.doc"""
***
    submodules(M::ModAlgAss, index::Int)

> Given a $G$-module $M$, it returns all the submodules of M of index q^index, where q is the order of the field

"""

function submodules(M::ModAlgAss{S, T}, index::Int; comp_factors=Tuple{ModAlgAss{S, T}, Int}[]) where {S, T}
  
  K=M.base_ring
  if index==M.dimension
    return T[zero_matrix(K,1,M.dimension)]
  end
  list=T[]
  if index>= M.dimension/2
    if index== M.dimension -1
      if isempty(comp_factors)
        lf=composition_factors(M, dimension=1)
      else
        lf=comp_factors
      end
      list=minimal_submodules(M,1,lf)
      return list
    end
    if isempty(comp_factors)
      lf=composition_factors(M)
    else 
      lf=comp_factors
    end
    for i=1: M.dimension-index-1
      minlist=minimal_submodules(M,i,lf)
      for x in minlist
        N, pivotindex= _actquo(x, M.action)
        #
        #  Recover the composition factors of the quotient
        #
        Sub=_actsub(x, M.action)
        lf1=[(x[1], x[2]) for x in lf]
        for j=1:length(lf1)
          if isisomorphic(lf1[j][1], Sub)
            if lf1[j][2]==1
              deleteat!(lf1,j)
            else
              lf1[j]=(lf1[j][1], lf1[j][2]-1)
            end
            break
          end
        end
        #
        #  Recursively ask for submodules and write their bases in terms of the given set of generators
        #
        ls=submodules(N,index, comp_factors=lf1)
        for a in ls
          s=zero_matrix(K,nrows(a)+nrows(x), M.dimension)
          for t=1:nrows(a)
            pos=0
            for j=1:M.dimension
              if j in pivotindex
               pos+=1
             else
               s[t,j]=a[t,j-pos]
              end
            end
          end
          for t=nrows(a)+1:nrows(s)
            for j=1:ncols(s)
              s[t,j]=x[t-nrows(a),j]
            end
          end
          push!(list,s)
        end
      end
    end
   
  #
  #  Eliminating repeatitions
  #

    for x in list
      rref!(x)
    end
    i=1
    while i<=length(list)
      k=i+1
      while k<=length(list)
        if list[i]==list[k]
          deleteat!(list, k)
        else 
          k+=1
        end
      end
      i+=1
    end
    append!(list,minimal_submodules(M,M.dimension-index, lf))
  else 
  #
  #  Duality
  # 
    M_dual=dual_space(M)
    dlist=submodules(M_dual, M.dimension-index)
    list=T[transpose(nullspace(x)[2]) for x in dlist]
  end 
  return list
    
end

## Make Nmod iteratible

Base.iterate(R::NmodRing) = (zero(R), zero(UInt))

function Base.iterate(R::NmodRing, st::UInt)
  if st == R.n - 1
    return nothing
  end

  return R(st + 1), st + 1
end

Base.eltype(::Type{NmodRing}) = nmod

Base.IteratorSize(::Type{NmodRing}) = Base.HasLength()

Base.length(R::NmodRing) = R.n

Base.iterate(R::GaloisField) = (zero(R), zero(UInt))

function Base.iterate(R::GaloisField, st::UInt)
  if st == R.n - 1
    return nothing
  end

  return R(st + 1), st + 1
end

Base.eltype(::Type{GaloisField}) = gfp_elem

Base.IteratorSize(::Type{GaloisField}) = Base.HasLength()

Base.length(R::GaloisField) = R.n

function powmod(f::Zmodn_poly, e::fmpz, g::Zmodn_poly)
  if nbits(e) <= 63
    return powmod(f, Int(e), g)
  else
    error("Not implemented yet")
  end
end
