// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Assets3D is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply {
  bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  mapping(uint256 => string) public uris;
  string public _name;
  string public _symbol;
  uint256 _totalSupply;

  constructor() ERC1155("") {
    _name = "OVR Assets3D";
    _symbol = "OVR3D";
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(URI_SETTER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function setURI(uint256 id, string memory newuri)
    public
    onlyRole(URI_SETTER_ROLE)
  {
    uris[id] = newuri;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function uri(uint256 id) public view override returns (string memory) {
    return uris[id];
  }

  //burn function override only for minter
  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public override onlyRole(MINTER_ROLE) {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
    //decrease totalSupply
    _totalSupply = _totalSupply - value;

    _burn(account, id, value);
  }

  //burn batch function override only for minter
  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public override onlyRole(MINTER_ROLE) {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
    //decrease totalSupply
    for (uint256 i = 0; i < ids.length; i++) {
      _totalSupply = _totalSupply - values[i];
    }

    _burnBatch(account, ids, values);
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyRole(MINTER_ROLE) {
    //increase totalSupply
    _totalSupply = _totalSupply + amount;
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyRole(MINTER_ROLE) {
    //increase totalSupply
    for (uint256 i = 0; i < ids.length; i++) {
      _totalSupply = _totalSupply + amounts[i];
    }
    _mintBatch(to, ids, amounts, data);
  }

  //mint with uri
  function mintWithURI(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data,
    string memory uriString
  ) public onlyRole(MINTER_ROLE) {
    //increase totalSupply
    _totalSupply = _totalSupply + amount;
    _mint(to, id, amount, data);
    uris[id] = uriString;
  }

  //batch mint with uris
  function mintBatchWithURI(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data,
    string[] memory uriStrings
  ) public onlyRole(MINTER_ROLE) {
    require(
      ids.length == uriStrings.length,
      "ids and uriStrings must be same length"
    );
    //increase totalSupply
    for (uint256 i = 0; i < ids.length; i++) {
      _totalSupply = _totalSupply + amounts[i];
    }
    _mintBatch(to, ids, amounts, data);
    for (uint256 i = 0; i < ids.length; i++) {
      uris[ids[i]] = uriStrings[i];
    }
  }

  //grant minter role
  function grantMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, account);
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
