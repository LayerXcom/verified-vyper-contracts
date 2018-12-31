# @dev Functions related to merkle tree.
# @author Ryuya Nakamura (@nrryuya)

@private
@constant
def _calcMerkleRoot(_leaf: bytes32, _index: uint256, _proof: bytes32[16]) -> bytes32:
    """
    @dev Compute the merkle root
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bytes32 Computed root of the Merkle tree.
    """
    computedHash: bytes32 = _leaf
    index: uint256 = _index

    for proofElement in _proof:
        if index % 2 == 0:
            computedHash = sha3(concat(computedHash, proofElement))
        else:
            computedHash = sha3(concat(proofElement, computedHash))
        index /= 2
    
    return computedHash


@public
@constant
def calcMerkleRoot(_leaf: bytes32, _index: uint256, _proof: bytes32[16]) -> bytes32:
    """
    @dev Compute the merkle root
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree, which starts with 1.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bytes32 Computed root of the Merkle tree.
    """
    return self._calcMerkleRoot(_leaf, _index, _proof)


@public
@constant
def verifyMerkleProof(_leaf: bytes32, _index: uint256, _rootHash: bytes32, _proof: bytes32[16]) -> bool:
    """
    @dev Checks that a leaf hash is contained in a root hash.
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree, which starts with 1.
    @param _rootHash Root of the Merkle tree.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bool whether the leaf hash is in the Merkle tree.
    """
    return self._calcMerkleRoot(_leaf, _index, _proof) == _rootHash
