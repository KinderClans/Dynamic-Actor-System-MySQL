CREATE TABLE IF NOT EXISTS `actors` 
(
  `dynamicActorID` int(3) NOT NULL AUTO_INCREMENT,
  `dynamicActorX` float NOT NULL,
  `dynamicActorY` float NOT NULL,
  `dynamicActorZ` float NOT NULL,
  `dynamicActorA` float NOT NULL,
  `dynamicActorVW` int(3) NOT NULL,
  `dynamicActorSkin` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;