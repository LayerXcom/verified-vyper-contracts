## How to get started

You need to install required python packages:

```
pip install -r requirements.txt
```

(Python 3.6 is required)

## Running the tests

You can run a test like:

```
pytest erc721/test_erc721.py
```

Or specific test case like:

```
pytest erc721/test_erc721.py::test_approve
```

You can also run the full test suite with:

```
pytest
```
