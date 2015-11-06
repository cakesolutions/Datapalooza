from neon.backends import gen_backend
from neon.layers import Affine, Dropout, GeneralizedCost, Linear
from neon.transforms import Rectlin, Logistic
from neon.transforms.cost import CrossEntropyMulti
from neon.initializers import Uniform, Constant
import time
from neon.optimizers import GradientDescentMomentum
from neon.models import Model
from neon.callbacks.callbacks import Callbacks
from neon.transforms import Misclassification
import os
import logging
from training import utils

class NeonCallbackParameters(object):
    pass

class MLPMeasurementModelTrainer(object):
    """Wrapper around a neon MLP model that controls training parameters and configuration of the model."""

    random_seed = 666  # Take your lucky number

    # Storage settings for the different output files
    Model_Filename = 'workout-mlp.pkl'
    Callback_Store_Filename = 'workout-mlp.h5'
    Intermediate_Model_Filename = 'workout-mlp-ep'

    def __init__(self, root_path, lrate=0.01, batch_size=30, max_epochs=10):
        """Initialize paths and loggers of the model."""
        # Storage director of the model and its snapshots
        self.root_path = root_path
        self.model_path = os.path.join(self.root_path, self.Model_Filename)
        utils.remove_if_exists(self.model_path)
        
        # Training settings
        self.lrate = lrate
        self.batch_size = batch_size
        self.max_epochs = max_epochs

        # Set logging output...
        for name in ["neon.util.persist"]:
            dslogger = logging.getLogger(name)
            dslogger.setLevel(40)

        print 'Epochs: %d Batch-Size: %d' % (self.max_epochs, self.batch_size)

    def generate_default_model(self, num_labels):
        """Generate layers and a MLP model using the given settings."""
        
        # implement the magic!

        return "Computed model!"

    def train(self, dataset, model=None):
        """Trains the passed model on the given dataset. If no model is passed, `generate_default_model` is used."""
        print "Starting training..."
        start = time.time()

        # The training will be run on the CPU. If a GPU is available it should be used instead.
        backend = gen_backend(backend='cpu',
                              batch_size=self.batch_size,
                              rng_seed=self.random_seed,
                              stochastic_round=False)

        cost = GeneralizedCost(
            name='cost',
            costfunc=CrossEntropyMulti())

        optimizer = GradientDescentMomentum(
            learning_rate=self.lrate,
            momentum_coef=0.9)

        # set up the model and experiment
        if not model:
            model = self.generate_default_model(dataset.num_labels)

        args = NeonCallbackParameters()
        args.output_file = os.path.join(self.root_path, self.Callback_Store_Filename)
        args.evaluation_freq = 1
        args.progress_bar = True
        args.epochs = self.max_epochs
        args.save_path = os.path.join(self.root_path, self.Intermediate_Model_Filename)
        args.serialize = 1
        args.history = 100
        args.model_file = None

        callbacks = Callbacks(model, dataset.train(), args, eval_set=dataset.test())

        # add a callback that saves the best model state
        callbacks.add_save_best_state_callback(self.model_path)

        # Uncomment line below to run on GPU using cudanet backend
        # backend = gen_backend(rng_seed=0, gpu='cudanet')
        model.fit(
            dataset.train(),
            optimizer=optimizer,
            num_epochs=self.max_epochs,
            cost=cost,
            callbacks=callbacks)

        print('Misclassification error = %.1f%%'
              % (model.eval(dataset.test(), metric=Misclassification()) * 100))
        print "Finished training!"
        end = time.time()
        print "Duration", end - start, "seconds"

        return model

    def layers(self, dataset, model):
        layerconfig = [dataset.num_features]
        for layer in model.layers.layers:
            if isinstance(layer, Linear):
                layerconfig.append(layer.nout)
        return layerconfig
