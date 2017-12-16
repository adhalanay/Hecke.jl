@testset "Relative maximal orders" begin

  Qx, x = FlintQQ["x"]
  f = x^2 + 36*x + 16
  K, a = NumberField(f, "a")
  Ky, y = K["y"]
  g = y^3 - 51*y^2 + 30*y - 28
  L, b = number_field(g, "b")

  Orel = MaximalOrder(L)
  Oabs = Hecke.maximal_order_via_absolute(L)
  Brel = Hecke.basis_pmat(Orel, Val{false})
  Babs = Hecke.basis_pmat(Oabs, Val{false})
  @test Hecke._spans_subset_of_pseudohnf(Brel, Babs, :lowerleft)
  @test Hecke._spans_subset_of_pseudohnf(Babs, Brel, :lowerleft)

  function monic_randpoly(S::PolyRing, dmin::Int, dmax::Int, n::Int)
    r = S()
    R = base_ring(S)
    d = rand(dmin:dmax)
    for i = 0:d - 1
      Nemo.setcoeff!(r, i, R(rand(-n:n)))
    end
    Nemo.setcoeff!(r, d, R(1))
    return r
  end

  Qx, x = FlintQQ["x"]
  for i = 1:5
    f = monic_randpoly(Qx, 2, 3, 100)
    while length(factor(f)) != 1
      f = monic_randpoly(Qx, 2, 3, 100)
    end
    K, a = NumberField(f, "a")

    Ky, y = K["y"]
    g = monic_randpoly(Ky, 2, 3, 100)
    while length(factor(g)) != 1
      g = monic_randpoly(Ky, 2, 3, 100)
    end
    L, b = number_field(g, "b")

    Orel = MaximalOrder(L)
    Oabs = Hecke.maximal_order_via_absolute(L)
    Brel = Hecke.basis_pmat(Orel, Val{false})
    Babs = Hecke.basis_pmat(Oabs, Val{false})
    @test Hecke._spans_subset_of_pseudohnf(Brel, Babs, :lowerleft)
    @test Hecke._spans_subset_of_pseudohnf(Babs, Brel, :lowerleft)
  end

  K, a = NumberField(x, "a")
  Ky, y = K["y"]
  for i= 1:5
    f = monic_randpoly(Ky, 8, 10, 100)
    while length(factor(f)) != 1
      f = monic_randpoly(Ky, 8, 10, 100)
    end
    L, b = number_field(f, "b")

    Orel = MaximalOrder(L)
    Oabs = Hecke.maximal_order_via_absolute(L)
    Brel = Hecke.basis_pmat(Orel, Val{false})
    Babs = Hecke.basis_pmat(Oabs, Val{false})
    @test Hecke._spans_subset_of_pseudohnf(Brel, Babs, :lowerleft)
    @test Hecke._spans_subset_of_pseudohnf(Babs, Brel, :lowerleft)
  end
end
