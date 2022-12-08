pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;
    address public monocarbon;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _monocarbon) public {
        monocarbon = _monocarbon;
        feeToSetter = msg.sender;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA) external returns (address pair) {
        require(feeToSetter == msg.sender, "Only the owner can add pairs.");
        require(tokenA != monocarbon, 'UniswapV2: IDENTICAL_ADDRESSES');
        require(tokenA != address(0), "UniswapV2: ZERO_ADDRESS");
        require(
            getPair[monocarbon][tokenA] == address(0),
            "UniswapV2: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(monocarbon, tokenA));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(monocarbon, tokenA);
        getPair[monocarbon][tokenA] = pair;
        getPair[tokenA][monocarbon] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(monocarbon, tokenA, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
