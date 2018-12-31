import pytest
from web3 import Web3

NULL_BYTE = b'\x00'
NULL_HASH = NULL_BYTE * 32
TREE_DEPTH = 16


# A test of FixedMerkle class
def test_create_membership_proof():
    leaves = [b'a', b'b', b'c']
    proof = FixedMerkle(2, leaves).create_membership_proof(leaves[2])
    assert proof == [Web3.sha3(NULL_HASH), Web3.sha3(Web3.sha3(leaves[0]) + Web3.sha3(leaves[1]))]


# A test of FixedMerkle class
def test_check_membership():
    leaves = [b'a', b'b', b'c']
    merkle = FixedMerkle(2, leaves)
    proof = merkle.create_membership_proof(leaves[2])
    assert merkle.check_membership(leaves[2], 2, proof)


@pytest.fixture
def c(get_contract):
    with open('../contracts/merkle/MerkleTree.vy') as f:
        code = f.read()
    c = get_contract(code)
    return c


def test_calcMerkleRoot(c, assert_tx_failed):
    leaves = range(2 ** TREE_DEPTH)
    merkle = FixedMerkle(TREE_DEPTH, leaves)
    test_index = 5
    test_leaf = leaves[test_index]
    proof = merkle.create_membership_proof(test_leaf)
    hashed_test_leaf = Web3.sha3(test_leaf)
    assert c.calcMerkleRoot(hashed_test_leaf, test_index, proof, call={"gas": 100000}) == merkle.root


def test_verifyMerkleProof(c):
    leaves = range(2 ** TREE_DEPTH)
    merkle = FixedMerkle(TREE_DEPTH, leaves)
    test_index = 5
    test_leaf = leaves[test_index]
    proof = merkle.create_membership_proof(test_leaf)
    hashed_test_leaf = Web3.sha3(test_leaf)
    assert merkle.check_membership(test_leaf, test_index, proof)
    assert c.verifyMerkleProof(hashed_test_leaf, test_index, merkle.root, proof, call={"gas": 100000})

    # Returns False if the index is wrong
    assert not c.verifyMerkleProof(hashed_test_leaf, test_index + 1, merkle.root, proof, call={"gas": 100000})

    # Returns False if the root hash is wrong
    assert not c.verifyMerkleProof(hashed_test_leaf, test_index, NULL_BYTE, proof, call={"gas": 100000})

    # Returns False if the proof is wrong
    assert not c.verifyMerkleProof(hashed_test_leaf, test_index, merkle.root, [NULL_BYTE] * TREE_DEPTH, call={"gas": 100000})


# These are modified from OmiseGo's work: 
# https://github.com/omisego/plasma-contracts/blob/v0.0.1/plasma_core/utils/merkle/fixed_merkle.py

class MerkleNode(object):

    def __init__(self, data, left=None, right=None):
        self.data = data
        self.left = left
        self.right = right


class FixedMerkle(object):

    def __init__(self, depth, leaves=[]):
        if depth < 1:
            raise ValueError('depth must be at least 1')

        self.depth = depth
        self.leaf_count = 2 ** depth

        if len(leaves) > self.leaf_count:
            raise ValueError('number of leaves should be at most depth ** 2')

        leaves = [Web3.sha3(leaf) for leaf in leaves]

        self.leaves = leaves + [Web3.sha3(NULL_HASH)] * (self.leaf_count - len(leaves))
        self.tree = [self.__create_nodes(self.leaves)]
        self.__create_tree(self.tree[0])

    def __create_nodes(self, leaves):
        return [MerkleNode(leaf) for leaf in leaves]

    def __create_tree(self, leaves):
        if len(leaves) == 1:
            self.root = leaves[0].data
            return

        next_level = len(leaves)
        tree_level = []

        for i in range(0, next_level, 2):
            combined = Web3.sha3(leaves[i].data + leaves[i + 1].data)
            next_node = MerkleNode(combined, leaves[i], leaves[i + 1])
            tree_level.append(next_node)

        self.tree.append(tree_level)
        self.__create_tree(tree_level)

    def check_membership(self, leaf, index, proof):
        hashed_leaf = Web3.sha3(leaf)
        computed_hash = hashed_leaf
        computed_index = index

        for i in range(self.depth):
            proof_segment = proof[i]

            if computed_index % 2 == 0:
                computed_hash = Web3.sha3(computed_hash + proof_segment)
            else:
                computed_hash = Web3.sha3(proof_segment + computed_hash)
            computed_index = computed_index // 2

        return computed_hash == self.root

    def create_membership_proof(self, leaf):
        hashed_leaf = Web3.sha3(leaf)
        if not self.__is_member(hashed_leaf):
            raise MemberNotExistException('leaf is not in the merkle tree')

        index = self.leaves.index(hashed_leaf)
        proof = []

        for i in range(self.depth):
            if index % 2 == 0:
                sibling_index = index + 1
            else:
                sibling_index = index - 1
            index = index // 2

            proof.append(self.tree[i][sibling_index].data)

        return proof

    def __is_member(self, leaf):
        return leaf in self.leaves

class MemberNotExistException(Exception):
    """raise when a leaf is not in the merkle tree"""
