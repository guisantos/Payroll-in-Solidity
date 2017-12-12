pragma solidity ^0.4.18;

import "./PayrollInterface.sol";
import "./Owned.sol";
import "./token/HumanStandardToken.sol";

contract Payroll is HumanStandardToken, PayrollInterface, Owned {

    //EVENTS
    event NewEmployee(uint256 employeeId, address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary);
    event DeleteEmployee();
    event UpdateSalary();

    //PROPERTY
    struct Employee {
        uint256 employeedId;
        address accountAddress;
        address[] allowedToken;
        uint256 yearlyEURSalary;
    }

    address[] private employeeIndex;
    mapping(address => Employee) private m_employees;

    struct Token {
        address token;
        uint256 EURExchangeRate;
    }

    mapping(address => Token) private m_token;

    address oracle;

    uint256 internal totalYearlySalary;
    //MODIFIER
    modifier onlyEmployee(){
        if (!(m_employees[msg.sender].accountAddress == msg.sender)) {
            revert();
        }
        _;
    }

    modifier onlyOracle(){
        if (!(oracle == msg.sender)) {
            revert();
        }
        _;
    }

    //CONSTRUTOR
    function Payroll() internal {
        var eurToken = Token(address(0), 0); 
        m_token[eurToken.token] = eurToken;
    }

    //FUNCTIONS
    function addEmployee(address accountAddress, address[] allowedTokens, uint256 initialYearlyEURSalary) onlyOwner public {
        require(accountAddress != address(0) && allowedTokens.length > 0 && initialYearlyEURSalary > 0);

        if (!employeeExist(accountAddress)) {
            var newEmployee = Employee(employeeIndex.length, accountAddress, allowedTokens, initialYearlyEURSalary);

            NewEmployee(employeeIndex.length, accountAddress, allowedTokens, initialYearlyEURSalary);

            m_employees[accountAddress] = newEmployee;
            employeeIndex.push(accountAddress);
        }
    }

    function setEmployeeSalary(uint256 employeeId, uint256 newSalary) onlyOwner public {
        address employeddAddress = getEmployeeById(employeeId);
        if (employeeExist(employeddAddress)) {
            m_employees[employeddAddress].yearlyEURSalary = newSalary;
        }
    }

    function removeEmployee(uint256 employeeId) onlyOwner public {
        address employeeToDelete = getEmployeeById(employeeId);

        if (employeeExist(employeeToDelete)) {
            var employeeToMove = employeeIndex[employeeIndex.length - 1];

            employeeIndex[employeeId] = employeeToMove;

            m_employees[employeeToMove].employeedId = employeeId;

            employeeIndex.length--;
        }
    }

    function getEmployeeCount() public view returns(uint256 employeeCount) {
        return employeeIndex.length;
    }

    function getEmployeeById(uint index) public view returns(address userAddress) {
        return employeeIndex[index];
    }

    function getEmployee(uint employeeId) public view returns(address employeeAddress, address[] allowedToken, uint256 salary) {
        Employee storage selectedEmployee = m_employees[getEmployeeById(employeeId)];

        employeeAddress = selectedEmployee.accountAddress;
        allowedToken = selectedEmployee.allowedToken;
        salary = selectedEmployee.yearlyEURSalary;
    }

    function employeeExist(address newAddress) public view returns (bool addressExist) {
        if (employeeIndex.length == 0)
            return false;
        
        return (employeeIndex[m_employees[newAddress].employeedId] == newAddress);
    }

    
    function addTokenFunds(address _spender, uint256 _value, bytes _extraData) public {
        //Calling from HumanStandardToken
        approveAndCall(_spender, _value, _extraData);
    }

    function setExchangeRate(address token, uint256 exchangeRate) public onlyOracle {
        require(exchangeRate > 0);

        HumanStandardToken standardToken = HumanStandardToken(m_token[token].token);
        m_token[token].EURExchangeRate = exchangeRate * standardToken.decimals();
    }    

    function addFunds() payable public onlyOwner {
    }

    function scapeHatch() public onlyOwner {
        msg.sender.transfer(this.balance);
    }
}