----------------------------------------------------------------------
-- This script demonstrates how to define a couple of different
-- models:
--   + linear
--   + 2-layer neural network (MLP)
	--   + convolutional network (ConvNet)
	--
	-- It's a good idea to run this script with the interactive mode:
	-- $ torch -i 2_model.lua
	-- this will give you a Torch interpreter at the end, that you
	-- can use to play with the model.
	--
	-- Clement Farabet
	----------------------------------------------------------------------

	require 'torch'   -- torch
	require 'image'   -- for image transforms
	require 'gfx.js'  -- to visualize the dataset
	require 'nn'      -- provides all sorts of trainable modules/layers
    require 'nnx'
	----------------------------------------------------------------------
	-- parse command line arguments
	if not opt then
	   print '==> processing options'
	      cmd = torch.CmdLine()
	   cmd:text()
	   cmd:text('SVHN Model Definition')
	      cmd:text()
	   cmd:text('Options:')
	      cmd:option('-model', 'convnet', 'type of model to construct: linear | mlp | convnet')
									      cmd:option('-visualize', true, 'visualize input data and weights during training')
										     cmd:text()
											    opt = cmd:parse(arg or {})
	end

	----------------------------------------------------------------------
	print '==> define parameters'

	-- N-class problem
        noutputs = 10

	-- input dimensions
        nfeats = 3
        width = 128
        height = 128
        ninputs = nfeats*width*height

	-- number of hidden units (for MLP only):
		nhiddens = ninputs / 2

    -- hidden units, filter sizes (for ConvNet only):
        nstates = {32,64,256,128}
        fanin = {1,4,4}
        filtsize = 5
        poolsize = 2
        stride = 2
        normkernel = image.gaussian1D(7)

	----------------------------------------------------------------------
	print '==> construct model'

	if opt.model == 'linear' then

	   -- Simple linear model
	   model = nn.Sequential()
	   model:add(nn.Reshape(ninputs))
	   model:add(nn.Linear(ninputs,noutputs))

	elseif opt.model == 'mlp' then

	   -- Simple 2-layer neural network, with tanh hidden units
	      model = nn.Sequential()
	   model:add(nn.Reshape(ninputs))
	   model:add(nn.Linear(ninputs,nhiddens))
	   model:add(nn.Tanh())
	   model:add(nn.Linear(nhiddens,noutputs))

	elseif opt.model == 'convnet' then

	    if opt.type == 'cuda' then 
        
            print 'Creating cuda model...'
	        -- a typical convolutional network, with locally-normalized hidden
		    -- units, and L2-pooling
	        -- Note: the architecture of this convnet is loosely based on Pierre Sermanet's
		    -- work on this dataset (http://arxiv.org/abs/1204.3968). In particular
	        -- the use of LP-pooling (with P=2) has a very positive impact on
		    -- generalization. Normalization is not done exactly as proposed in
	        -- the paper, and low-level (first layer) features are not fed to
		    -- the classifier.
            -- Container:
            model = nn.Sequential()
	        
	        -- stage 1 : filter bank -> squashing -> L2 pooling -> normalization
            model:add(nn.SpatialConvolutionMM(nfeats, nstates[1], filtsize, filtsize))
	        --model:add(nn.Threshold(0,1e-6))
	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        model:add(nn.SpatialMaxPooling(poolsize, poolsize, stride, stride))
	        --model:add(nn.Dropout(0.5))
	        --model:add(nn.SpatialSubtractiveNormalization(nstates[1], normkernel))
	        
	        -- stage 2 : filter bank -> squashing -> L2 pooling -> normalization
            model:add(nn.SpatialConvolutionMM(nstates[1], nstates[2], filtsize, filtsize))
	        --model:add(nn.Threshold(0,1e-6))
   	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        model:add(nn.SpatialMaxPooling(poolsize, poolsize, stride, stride))
	        --model:add(nn.Dropout(0.5))
        	--model:add(nn.SpatialSubtractiveNormalization(nstates[2], normkernel))
        	
        	-- stage 3 : filter bank -> squashing -> L2 pooling -> normalization
            model:add(nn.SpatialConvolutionMM(nstates[2], nstates[3], filtsize, filtsize))
	        --model:add(nn.Threshold(0,1e-6))
   	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        model:add(nn.SpatialMaxPooling(poolsize, poolsize, stride, stride))
        	-- model:add(nn.SpatialSubtractiveNormalization(nstates[2], normkernel))
	        
	        -- stage 4 : standard 2-layer neural network
            --model:add(nn.View(nstates[2]*5*5))
            model:add(nn.View(nstates[3]*12*12))
            --model:add(nn.Dropout(0.5)) -- Adding dropout
	        --model:add(nn.Linear(nstates[2]*5*5, nstates[3]))
	        model:add(nn.Linear(nstates[3]*12*12, nstates[4]))
	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        --model:add(nn.Dropout(0.5))
	        --model:add(nn.Linear(256, 64))
	        --model:add(nn.Threshold(0,1e-6))
   	        --model:add(nn.Tanh())
	        --model:add(nn.ReLU())   
	        --model:add(nn.Dropout(0.5))	        
	        model:add(nn.Linear(nstates[4], noutputs))
	    
	    else 
	        -- a typical convolutional network, with locally-normalized hidden
		    -- units, and L2-pooling
	        -- Note: the architecture of this convnet is loosely based on Pierre Sermanet's
		    -- work on this dataset (http://arxiv.org/abs/1204.3968). In particular
	        -- the use of LP-pooling (with P=2) has a very positive impact on
		    -- generalization. Normalization is not done exactly as proposed in
	        -- the paper, and low-level (first layer) features are not fed to
		    -- the classifier.
            -- Container:
            model = nn.Sequential()
	        
	        -- stage 1 : filter bank -> squashing -> L2 pooling -> normalization
            --model:add(nn.SpatialConvolutionMM(nfeats, nstates[1], filtsize, filtsize))
            model:add(nn.SpatialConvolutionMap(nn.tables.random(nfeats, nstates[1], fanin[1]), filtsize, filtsize))
	        --model:add(nn.Threshold(0,1e-6))
	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        model:add(nn.SpatialMaxPooling(poolsize, poolsize, stride, stride))
	        --model:add(nn.Dropout(0.5))
	        model:add(nn.SpatialSubtractiveNormalization(nstates[1], normkernel))
	        
	        -- stage 2 : filter bank -> squashing -> L2 pooling -> normalization
            --model:add(nn.SpatialConvolutionMM(nstates[1], nstates[2], filtsize, filtsize))
            model:add(nn.SpatialConvolutionMap(nn.tables.random(nstates[1], nstates[2], fanin[2]), filtsize, filtsize))
	        --model:add(nn.Threshold(0,1e-6))
   	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        model:add(nn.SpatialMaxPooling(poolsize, poolsize, stride, stride))
	        --model:add(nn.Dropout(0.5))
        	model:add(nn.SpatialSubtractiveNormalization(nstates[2], normkernel))
        	
        	-- stage 3 : filter bank -> squashing -> L2 pooling -> normalization
            --model:add(nn.SpatialConvolutionMM(nstates[1], nstates[3], filtsize, filtsize))
            model:add(nn.SpatialConvolutionMap(nn.tables.random(nstates[2], nstates[3], fanin[3]), filtsize, filtsize))
	        --model:add(nn.Threshold(0,1e-6))
   	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        model:add(nn.SpatialMaxPooling(poolsize, poolsize, stride, stride))
        	model:add(nn.SpatialSubtractiveNormalization(nstates[3], normkernel))
	        
	        -- stage 4 : standard 2-layer neural network
            --model:add(nn.View(nstates[2]*5*5))
            model:add(nn.View(nstates[3]*4*4))
            --model:add(nn.Dropout(0.5)) -- Adding dropout
	        --model:add(nn.Linear(nstates[2]*5*5, nstates[3]))
	        model:add(nn.Linear(nstates[3]*4*4, nstates[4]))
	        model:add(nn.Tanh())
	        --model:add(nn.ReLU())
	        --model:add(nn.Dropout(0.5))
	        --model:add(nn.Linear(256, 64))
	        --model:add(nn.Threshold(0,1e-6))
   	        --model:add(nn.Tanh())
	        --model:add(nn.ReLU())   
	        --model:add(nn.Dropout(0.5))	        
	        model:add(nn.Linear(nstates[4], noutputs))
	    
	    end

	    else

	       error('unknown -model')

	       end

	       ----------------------------------------------------------------------
	       print '==> here is the model:'
	       print(model)

	----------------------------------------------------------------------
	-- Visualization is quite easy, using gfx.image().

	if opt.visualize then
	   if opt.model == 'convnet' then
         print '==> visualizing ConvNet filters'
		 gfx.image(model:get(1).weight, {zoom=2, legend='L1'})
		 gfx.image(model:get(5).weight, {zoom=2, legend='L2'})
       end
	end
