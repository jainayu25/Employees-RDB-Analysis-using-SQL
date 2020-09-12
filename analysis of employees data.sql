#Selecting Database
USE employees;

#Checking total no. of department
SELECT * FROM departments;
SELECT COUNT(DISTINCT(dept_no)) FROM departments;

#Checking total no. of employe 
SELECT * FROM employees LIMIT 10;

#Lets check for total no. of employees
#Checking if any employe have two emp_no. (possible in case of rejoining) or Checking for Duplicates
SELECT * FROM employees e
        JOIN (SELECT *, COUNT(*) FROM employees a
			  GROUP BY birth_date , first_name , last_name , gender
			  HAVING COUNT(*) > 1) a ON e.birth_date = a.birth_date
        AND e.first_name = a.first_name
        AND e.last_name = a.last_name
        AND e.gender = a.gender
        AND e.hire_date != a.hire_date;
#No Duplicates value but there are 5 employees that have rejoined the department

# Retriving information of all department manager 
SELECT e.first_name , e.last_name, e.birth_date, e.hire_date, e.emp_no, d.dept_no , d.from_date, d.to_date 
FROM employees e
JOIN dept_manager d ON e.emp_no = d.emp_no;         

# Retriving information of employees with last name "Markovitch" and checking if any of them is manager or not
SELECT  e.last_name, e.emp_no, d.dept_no
FROM employees e
LEFT JOIN dept_manager d on e.emp_no = d.emp_no
WHERE e.last_name = "Markovitch"
ORDER BY d.dept_no DESC, e.emp_no;

# Retriving titles of all employees with first name "Margareta" and last name "Markovitch"
SELECT e.first_name , e.last_name, e.birth_date, e.hire_date, e.emp_no, t.title 
FROM employees e
JOIN titles t ON e.emp_no = t.emp_no
WHERE e.first_name ="Margareta" AND e.last_name = "Markovitch"
ORDER BY e.emp_no;

# Retriving information of all manager with hiring date and start date
SELECT e.first_name, e.last_name, e.hire_date, e.emp_no, d.dept_name, dm.from_date AS manager_date, t.title
FROM employees e
JOIN dept_manager dm ON e.emp_no = dm.emp_no
JOIN departments d ON dm.dept_no = d.dept_no
JOIN titles t ON e.emp_no = t.emp_no
WHERE t.title = "Manager"
order by e.emp_no;

# Retriving information of all department manager who were hired between 1st of JAN 1990 and  1st of JAN 1995
SELECT * FROM dept_manager 
WHERE emp_no IN (SELECT emp_no 
                 FROM employees 
                 WHERE hire_date BETWEEN "1990-01-01" AND "1995-01-01");
                 
# Retriving Entire infromation of employees who is "Assistant engineer"
SELECT * FROM employees e 
WHERE EXISTS (SELECT * FROM titles t
              WHERE t.emp_no = e.emp_no
              AND t.title = "Assistant engineer");

# Checking how many male and how many female managers do we have in the ‘employees’ database
SELECT e.gender , COUNT(dm.emp_No)
FROM employees e 
JOIN dept_manager dm ON e.emp_no = dm.emp_no
GROUP BY e.gender;

# Checking for Breakdown of male and female employees every year after 1990
SELECT YEAR(d.from_date) AS calender_year, e.gender, COUNT(e.emp_no) AS no_of_emp
FROM employees e
JOIN dept_emp d ON e.emp_no = d.emp_no
GROUP BY calender_year, e.gender 
HAVING calender_year > 1990
ORDER BY calender_year;

#Comparing the number of male managers to the number of female managers from different departments for each year
SELECT d.dept_name, ee.gender, dm.emp_no, dm.from_date, dm.to_date, e.calendar_year,
 CASE WHEN YEAR(dm.to_date) >= e.calendar_year AND YEAR(dm.from_date) <= e.calendar_year THEN 1 ELSE 0
    END AS active
FROM (SELECT YEAR(hire_date) AS calendar_year
    FROM employees GROUP BY calendar_year) e
    CROSS JOIN dept_manager dm
    JOIN departments d ON dm.dept_no = d.dept_no
    JOIN employees ee ON dm.emp_no = ee.emp_no
ORDER BY calendar_year, dm.emp_no;

#Comparing the average salary of female versus male employees and add a filter allowing you to see that per each department
SELECT  e.gender, YEAR(s.from_date) AS calender_year ,ROUND(AVG(s.salary),2) AS salary, d.dept_name
FROM salaries s
JOIN employees e ON s.emp_no = e.emp_no
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON de.dept_no = d.dept_no
GROUP BY d.dept_name, e.gender, calender_year
ORDER BY d.dept_name;

#Retriving Average salary of male and female employees of each department
SELECT d.dept_name, ROUND(AVG(salary), 2) AS salary, e.gender
FROM salaries s 
JOIN employees e ON s.emp_no = e.emp_no
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON d.dept_no = de.dept_no
GROUP BY d.dept_name, e.gender
ORDER BY dept_name; 

#Total no. of employees different departments
SELECT dept_no, COUNT(dept_no) FROM dept_emp
GROUP BY dept_no
ORDER BY dept_no;

#Creating a procedure that give you the last departemnt of employee has worked in
DELIMITER $$
CREATE PROCEDURE emp_last_dept( IN p_emp_no integer)
BEGIN
SELECT d.dept_name, de.dept_no, e.emp_no
FROM employees e 
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON de.dept_no = d.dept_no
WHERE e.emp_no = p_emp_no AND de.from_date = (SELECT MAX(from_date) 
                                               FROM dept_emp
                                               WHERE emp_no = p_emp_no);
END $$
DELIMITER ;
CALL employees.emp_last_dept(10010);

# Total number of contract of salary higher than 100000 remains for more than a year
SELECT COUNT(*) FROM salaries
WHERE salary > 100000 AND datediff( to_date, from_date) > 365; 

#Create an SQL stored procedure that will allow you to obtain the average male and female salary per department within a certain salary range. 
DELIMITER $$
CREATE PROCEDURE filter_salary(IN p_min_salary FLOAT, IN p_max_salary FLOAT)
BEGIN
SELECT e.gender, d.dept_name, AVG(s.salary) as avg_salary
FROM salaries s
JOIN employees e ON s.emp_no = e.emp_no    
JOIN dept_emp de ON de.emp_no = e.emp_no
JOIN departments d ON d.dept_no = de.dept_no
WHERE s.salary BETWEEN p_min_salary AND p_max_salary
GROUP BY d.dept_no, e.gender;
END$$
DELIMITER ;  
CALL filter_salary (50000,90000);

# Creating a procedure that will provide average salary of all employees
DELIMITER $$
CREATE PROCEDURE avg_salary()
BEGIN SELECT AVG(salary)
FROM salaries; 
END$$
DELIMITER ;
CALL avg_salary;

# Procedure that uses as parameters the first and the last name of an individual, and returns their employee number.
DELIMITER $$
CREATE PROCEDURE emp_info(in p_first_name varchar(255), in p_last_name varchar(255), out p_emp_no integer)
BEGIN
SELECT e.emp_no
INTO p_emp_no FROM employees e
WHERE e.first_name = p_first_name
AND e.last_name = p_last_name;
END$$
DELIMITER ;

#

#Selecting number of employees with first_name "Elvis"
SELECT COUNT(*) FROM employees
WHERE first_name = "Elvis";

#Retriving number of Female employees whose first_name is "Kellie"
SELECT COUNT(*) FROM employees
WHERE gender= "F" AND first_name= "Kellie";

#Retriving a list of employees whose first_name is "Kellie" or "Aruna"
SELECT * FROM employees
WHERE first_name = "Kellie" OR first_name ="Aruna";
#Using IN statement
SELECT * FROM employees
WHERE first_name IN ("Kellie","Aruna");

# Retriving a list all female employees whose first_name is "Kellie" or "Aruna"
SELECT * FROM employees
WHERE gender="F" AND (first_name = "Kellie" OR first_name = "Aruna");

# Retriving a list of employees whose first_name is starts with "Mark"4
SELECT * FROM employees
WHERE first_name LIKE ("Mark%"); 

#Retriving a list og employees hired in year 2000
SELECT * FROM employees
WHERE hire_date LIKE ("%2000%");

#Retriving a list of employee with employee number of 5 digit and starts with "1000"
SELECT * FROM employees
WHERE emp_no LIKE ("1000_");

#Retriving information of employees whose first name contains "Jack"
SELECT * FROM employees
WHERE first_name LIKE ("%Jack%");

#Retriving information of employees whose first name not contains "Jack"
SELECT * FROM employees
WHERE first_name NOT LIKE ("%Jack%");

#Retriving employee number of employees whose salary is between 66000 and 70000
SELECT * FROM salaries
WHERE salary BETWEEN 66000 AND 70000;

#Retriving information of department with not NULL department number
SELECT * FROM departments
WHERE dept_no IS NOT NULL;

#Retriving Female employees hired in year 2000
SELECT * FROM employees
WHERE gender = "F" AND hire_date >= "2000-01-01";

#List of employees with salary greater than 150000
SELECT * FROM salaries
WHERE salary > 150000;

# Retriving information of all employees with different hiring dates
SELECT DISTINCT hire_date FROM employees;

#Retriving total number of employees
SELECT COUNT(*) FROM titles
WHERE title= "Manager";

SELECT COUNT(*) FROM dept_manager;

#Retriving list of number of employees having salary more than 80000
SELECT salary, COUNT(emp_no) AS emp_with_same_salary FROM salaries
WHERE salary > 80000
GROUP BY salary
ORDER BY salary;

#Retriving employees with Avg salary greater than 120000 per Annum
SELECT *, AVG(salary) FROM salaries
GROUP BY emp_no
HAVING AVG(salary) > 120000
ORDER BY emp_no;

#Retriving employee numbers of all individuals who have signed more than 1 contract after the 1st of January 2000.
SELECT emp_no FROM dept_emp
WHERE from_date > 2000-01-01
GROUP BY emp_no
HAVING COUNT(from_date) > 1
ORDER BY emp_no;

#Total amount of money spent on salary after 1997-01-01
SELECT SUM(salary) FROM salaries
WHERE from_date > "1997-01-01";

#Avg money spent on salary after 1997-01-01
SELECT ROUND(AVG(salary),2) FROM salaries
WHERE from_date > "1997-01-01";

# Use of COALESCE():
SELECT * FROM departments
ORDER BY dept_no;

INSERT INTO department_duplicate (dept_no,dept_name)
SELECT dept_no, dept_name FROM departments;

SELECT * FROM department_duplicate
ORDER BY dept_no;
INSERT INTO department_duplicate (dept_name)
VALUE ("Public Limited");

SELECT dept_no, dept_name, COALESCE(dept_no,dept_name) AS dept_info 
FROM department_duplicate;

INSERT INTO department_duplicate (dept_no)
VALUE ("d010"),("d011"); 

SELECT IFNULL(dept_no, "N/A") as dept_no,
IFNULL(dept_name, "Department name not provided") as dept_name,
COALESCE(dept_no, dept_name) AS dept_info
FROM department_duplicate;

DROP TABLE IF EXISTS department_duplicate;

SELECT * FROM
    (SELECT e.emp_no, e.first_name, e.last_name, NULL AS dept_no, NULL AS from_date
    FROM employees e
    WHERE last_name = 'Denis' UNION SELECT NULL AS emp_no, NULL AS first_name, NULL AS last_name,
            dm.dept_no, dm.from_date FROM dept_manager dm) as a
ORDER BY -a.emp_no DESC;
