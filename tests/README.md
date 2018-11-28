## How to get started

Python 3.6 is required.
For settting up Python 3 environment, [virtualenv](https://virtualenv.pypa.io/en/stable/) is commonly used, like:

```
# once
virtualenv -p python3 venv

# each session
. venv/bin/activate
```

Then install required packages:

```
pip install -r requirements.txt
```

## Running the tests

You can run the tests:

```
pytest
```