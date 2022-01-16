# Mode interactif



ag(:infile,p12)
inst = Instance(ag(:infile))
ag(:nbh,:swap_and_shift)
ag(:presort,:target)
svd = DescentSolver(inst)
solve!(svd, nb_cons_reject_max=10000, durationmax = 300)


# Mode terminal

julia ./bin/run.jl timing --planes p3,p4,p5,p8,p6,p7,p9,p1,p10,p2 data/01.alp

julia ./bin/run.jl tim -t lp -i data/01.alp  -p 3,4,5,6,7,8,9,1,10,2

julia ./bin/run.jl descent -n 100 --dur 300  --presort target  data/01.alp

julia ./bin/run.jl descent -n 100 --dur 1000  --presort target  data/05.alp

julia ./bin/run.jl descent -n 100 --dur 1000  data/09.alp

julia ./bin/run.jl descent -n 50  --presort target  data/05.alp

julia ./bin/run.jl carlo  --itermax 1  data/01.alp
