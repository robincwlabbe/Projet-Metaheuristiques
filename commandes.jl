# Mode interactif

ag(:infile,p11)
inst = Instance(ag(:infile))
sol = Solution(inst)
sv = DescentSolver(sol.inst)
solve!(sv,durationmax = 300, nb_cons_reject_max = 10000, mode = "bloc_shuffle")


# Mode terminal

julia ./bin/run.jl timing --planes p3,p4,p5,p8,p6,p7,p9,p1,p10,p2 data/01.alp

julia ./bin/run.jl tim -t lp -i data/01.alp  -p 3,4,5,6,7,8,9,1,10,2

julia ./bin/run.jl descent -n 100 --dur 300  --presort target  data/01.alp

julia ./bin/run.jl descent -n 100 --dur 1000  --presort target  data/05.alp

julia ./bin/run.jl descent -n 100 --dur 1000  data/09.alp

julia ./bin/run.jl descent -n 50  --presort target  data/05.alp

julia ./bin/run.jl carlo  --itermax 1  data/01.alp
