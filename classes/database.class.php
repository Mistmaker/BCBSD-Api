<?php

class Database
{

	private $host      = DB_HOST;
	private $user      = DB_USER;
	private $pass      = DB_PASS;
	private $dbname    = DB_NAME;
	private $dbh;
	private $error;
	private $stmt;

	public function __construct()
	{
		$port = defined('DB_PORT') ? DB_PORT : 5432;
		try {
			$this->dbh = new PDO("pgsql:host={$this->host};port={$port};dbname={$this->dbname}", $this->user, $this->pass, [
				PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
			]);
		} catch (PDOException $e) {
			// No se muestra el detalle: el mensaje de PDO puede incluir datos de la conexión.
			error_log('Error de conexión a la base de datos: ' . $e->getMessage());
			throw new RuntimeException('No se pudo conectar a la base de datos.');
		}
	}

	public function query($query)
	{
		$this->stmt = $this->dbh->prepare($query);
	}


	public function bind($param, $value, $type = null)
	{
		if (is_null($type)) {
			switch (true) {
				case is_int($value):
					$type = PDO::PARAM_INT;
					break;
				case is_bool($value):
					$type = PDO::PARAM_BOOL;
					break;
				case is_null($value):
					$type = PDO::PARAM_NULL;
					break;
				default:
					$type = PDO::PARAM_STR;
			}
		}
		$this->stmt->bindValue($param, $value, $type);
	}

	public function execute()
	{
		return $this->stmt->execute();
	}

	public function resultset()
	{
		$this->execute();
		return $this->stmt->fetchAll(PDO::FETCH_ASSOC);
	}

	public function single()
	{
		$this->execute();
		return $this->stmt->fetch(PDO::FETCH_ASSOC);
	}

	public function rowCount()
	{
		return $this->stmt->rowCount();
	}

	public function lastInsertId()
	{
		return $this->dbh->lastInsertId();
	}

	public function beginTransaction()
	{
		return $this->dbh->beginTransaction();
	}

	public function endTransaction()
	{
		// return $this->dbh->commit();
		if ($this->dbh->inTransaction()) {
			return $this->dbh->commit();
		}
		return false;
	}

	public function cancelTransaction()
	{
		// return $this->dbh->rollBack();
		if ($this->dbh->inTransaction()) {
			return $this->dbh->rollBack();
		}
		return false;
	}

	public function debugDumpParams()
	{
		return $this->stmt->debugDumpParams();
	}

	public function closeConnection()
	{
		$this->stmt = null;
		$this->dbh = null;
	}

	public function getErrors()
	{
		return $this->stmt->errorInfo();
	}
}
