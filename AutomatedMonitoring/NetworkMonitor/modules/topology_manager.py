#!/usr/bin/env python3

import logging
from typing import Dict, List, Any, Optional, Set, Tuple
from dataclasses import dataclass
from datetime import datetime
import time
import networkx as nx
from enum import Enum
import json
import pysnmp.hlapi as snmp
from scapy.all import *

logger = logging.getLogger('NetworkMonitor.TopologyManager')

class LinkType(Enum):
    PHYSICAL = "physical"
    LOGICAL = "logical"
    VLAN = "vlan"
    LAG = "lag"

class LayerType(Enum):
    L2 = "layer2"
    L3 = "layer3"
    L4 = "layer4"

@dataclass
class NetworkLink:
    source_device: str
    target_device: str
    source_interface: str
    target_interface: str
    link_type: LinkType
    layer: LayerType
    speed: int
    status: str
    vlan: Optional[int] = None
    lag_id: Optional[str] = None
    metrics: Dict[str, Any] = None

@dataclass
class TopologyNode:
    device_ip: str
    device_name: str
    device_type: str
    location: str
    interfaces: Dict[str, Dict]
    neighbors: Dict[str, 'NetworkLink']
    vlans: List[int] = None
    routes: List[Dict] = None

class TopologyManager:
    def __init__(self, config: Dict[str, Any]):
        """Initialize the Topology Manager."""
        self.config = config
        self.topology: nx.Graph = nx.Graph()
        self.layer2_topology: nx.Graph = nx.Graph()
        self.layer3_topology: nx.Graph = nx.Graph()
        self.nodes: Dict[str, TopologyNode] = {}
        self.history: List[Dict] = []
        self.last_update = 0
        self.update_interval = config.get('update_interval', 3600)  # 1 hour default

    def update_topology(self) -> nx.Graph:
        """Update network topology."""
        current_time = time.time()
        if current_time - self.last_update < self.update_interval:
            return self.topology

        try:
            # Store previous topology state for change detection
            previous_topology = self.topology.copy()

            # Clear current topology
            self.topology.clear()
            self.layer2_topology.clear()
            self.layer3_topology.clear()

            # Discover Layer 2 topology
            self._discover_layer2_topology()

            # Discover Layer 3 topology
            self._discover_layer3_topology()

            # Merge Layer 2 and Layer 3 topologies
            self._merge_topologies()

            # Detect and record changes
            self._detect_topology_changes(previous_topology)

            self.last_update = current_time
            return self.topology

        except Exception as e:
            logger.error(f"Error updating topology: {e}")
            return self.topology

    def _discover_layer2_topology(self):
        """Discover Layer 2 network topology using various protocols."""
        try:
            # Discover using LLDP
            self._discover_lldp_topology()
            
            # Discover using CDP (for Cisco devices)
            self._discover_cdp_topology()
            
            # Discover using spanning tree information
            self._discover_stp_topology()
            
            # Discover using MAC address tables
            self._discover_mac_topology()
            
        except Exception as e:
            logger.error(f"Error discovering Layer 2 topology: {e}")

    def _discover_layer3_topology(self):
        """Discover Layer 3 network topology."""
        try:
            # Discover using routing tables
            self._discover_routing_topology()
            
            # Discover using ARP tables
            self._discover_arp_topology()
            
            # Discover using OSPF neighbors
            self._discover_ospf_topology()
            
            # Discover using BGP neighbors
            self._discover_bgp_topology()
            
        except Exception as e:
            logger.error(f"Error discovering Layer 3 topology: {e}")

    def _discover_lldp_topology(self):
        """Discover topology using LLDP."""
        for device in self.nodes.values():
            try:
                lldp_neighbors = self._get_lldp_neighbors(device)
                for neighbor in lldp_neighbors:
                    self._add_link(
                        source=device.device_ip,
                        target=neighbor['remote_ip'],
                        link_type=LinkType.PHYSICAL,
                        layer=LayerType.L2,
                        source_interface=neighbor['local_interface'],
                        target_interface=neighbor['remote_interface']
                    )
            except Exception as e:
                logger.error(f"Error discovering LLDP topology for {device.device_ip}: {e}")

    def _discover_cdp_topology(self):
        """Discover topology using CDP (Cisco Discovery Protocol)."""
        for device in self.nodes.values():
            try:
                cdp_neighbors = self._get_cdp_neighbors(device)
                for neighbor in cdp_neighbors:
                    self._add_link(
                        source=device.device_ip,
                        target=neighbor['remote_ip'],
                        link_type=LinkType.PHYSICAL,
                        layer=LayerType.L2,
                        source_interface=neighbor['local_interface'],
                        target_interface=neighbor['remote_interface']
                    )
            except Exception as e:
                logger.error(f"Error discovering CDP topology for {device.device_ip}: {e}")

    def _discover_stp_topology(self):
        """Discover topology using Spanning Tree Protocol information."""
        for device in self.nodes.values():
            try:
                stp_info = self._get_stp_info(device)
                for port_info in stp_info:
                    if port_info['state'] == 'forwarding':
                        self._add_link(
                            source=device.device_ip,
                            target=port_info['neighbor_bridge'],
                            link_type=LinkType.PHYSICAL,
                            layer=LayerType.L2,
                            source_interface=port_info['local_port'],
                            target_interface=port_info['remote_port']
                        )
            except Exception as e:
                logger.error(f"Error discovering STP topology for {device.device_ip}: {e}")

    def _discover_routing_topology(self):
        """Discover topology using routing information."""
        for device in self.nodes.values():
            try:
                routes = self._get_routing_table(device)
                for route in routes:
                    if route['type'] == 'connected':
                        self._add_link(
                            source=device.device_ip,
                            target=route['network'],
                            link_type=LinkType.LOGICAL,
                            layer=LayerType.L3,
                            source_interface=route['interface'],
                            target_interface='N/A'
                        )
            except Exception as e:
                logger.error(f"Error discovering routing topology for {device.device_ip}: {e}")

    def _merge_topologies(self):
        """Merge Layer 2 and Layer 3 topologies into a complete network graph."""
        try:
            # Add all nodes and edges from both topologies
            self.topology.add_nodes_from(self.layer2_topology.nodes(data=True))
            self.topology.add_edges_from(self.layer2_topology.edges(data=True))
            
            self.topology.add_nodes_from(self.layer3_topology.nodes(data=True))
            self.topology.add_edges_from(self.layer3_topology.edges(data=True))
            
            # Identify and merge duplicate links
            self._merge_duplicate_links()
            
        except Exception as e:
            logger.error(f"Error merging topologies: {e}")

    def _merge_duplicate_links(self):
        """Identify and merge duplicate links between the same devices."""
        duplicate_edges = []
        for edge in self.topology.edges(data=True):
            source, target = edge[0], edge[1]
            # Find all edges between these nodes
            edges = self.topology.get_edge_data(source, target)
            if len(edges) > 1:
                duplicate_edges.append((source, target))
        
        # Merge duplicate edges
        for source, target in duplicate_edges:
            edges = self.topology.get_edge_data(source, target)
            merged_data = self._merge_edge_data(edges)
            # Remove old edges and add merged edge
            self.topology.remove_edge(source, target)
            self.topology.add_edge(source, target, **merged_data)

    def _merge_edge_data(self, edges: Dict) -> Dict:
        """Merge data from multiple edges between the same nodes."""
        merged = {
            'link_types': set(),
            'layers': set(),
            'interfaces': set(),
            'metrics': {}
        }
        
        for edge in edges.values():
            merged['link_types'].add(edge['link_type'])
            merged['layers'].add(edge['layer'])
            merged['interfaces'].add((edge['source_interface'], edge['target_interface']))
            if 'metrics' in edge:
                merged['metrics'].update(edge['metrics'])
        
        return merged

    def _detect_topology_changes(self, previous_topology: nx.Graph):
        """Detect and record changes in network topology."""
        try:
            changes = {
                'timestamp': time.time(),
                'added_nodes': [],
                'removed_nodes': [],
                'added_links': [],
                'removed_links': [],
                'modified_links': []
            }
            
            # Detect node changes
            current_nodes = set(self.topology.nodes())
            previous_nodes = set(previous_topology.nodes())
            
            changes['added_nodes'] = list(current_nodes - previous_nodes)
            changes['removed_nodes'] = list(previous_nodes - current_nodes)
            
            # Detect link changes
            current_edges = set(self.topology.edges())
            previous_edges = set(previous_topology.edges())
            
            changes['added_links'] = list(current_edges - previous_edges)
            changes['removed_links'] = list(previous_edges - current_edges)
            
            # Detect modified links
            common_edges = current_edges.intersection(previous_edges)
            for edge in common_edges:
                current_data = self.topology.get_edge_data(*edge)
                previous_data = previous_topology.get_edge_data(*edge)
                if current_data != previous_data:
                    changes['modified_links'].append({
                        'edge': edge,
                        'previous': previous_data,
                        'current': current_data
                    })
            
            # Record changes if any occurred
            if any(changes.values()):
                self.history.append(changes)
                logger.info(f"Topology changes detected: {json.dumps(changes, default=str)}")
                
        except Exception as e:
            logger.error(f"Error detecting topology changes: {e}")

    def _add_link(self, source: str, target: str, link_type: LinkType,
                 layer: LayerType, source_interface: str, target_interface: str,
                 **kwargs):
        """Add a link to the appropriate topology graph."""
        link_data = {
            'link_type': link_type,
            'layer': layer,
            'source_interface': source_interface,
            'target_interface': target_interface,
            'timestamp': time.time(),
            **kwargs
        }
        
        if layer == LayerType.L2:
            self.layer2_topology.add_edge(source, target, **link_data)
        elif layer == LayerType.L3:
            self.layer3_topology.add_edge(source, target, **link_data)

    def get_path(self, source: str, target: str) -> List[str]:
        """Find the shortest path between two devices."""
        try:
            return nx.shortest_path(self.topology, source, target)
        except nx.NetworkXNoPath:
            logger.error(f"No path found between {source} and {target}")
            return []

    def get_redundant_paths(self, source: str, target: str) -> List[List[str]]:
        """Find all redundant paths between two devices."""
        try:
            return list(nx.all_simple_paths(self.topology, source, target))
        except Exception as e:
            logger.error(f"Error finding redundant paths: {e}")
            return []

    def get_critical_links(self) -> List[Tuple[str, str]]:
        """Identify critical links (bridges) in the topology."""
        try:
            return list(nx.bridges(self.topology))
        except Exception as e:
            logger.error(f"Error finding critical links: {e}")
            return []

    def get_topology_changes(self, start_time: float, end_time: float) -> List[Dict]:
        """Get topology changes within the specified time range."""
        return [
            change for change in self.history
            if start_time <= change['timestamp'] <= end_time
        ]

    def export_topology(self, format: str = 'json') -> str:
        """Export the current topology in the specified format."""
        try:
            if format == 'json':
                return nx.node_link_data(self.topology)
            elif format == 'graphml':
                return nx.generate_graphml(self.topology)
            else:
                raise ValueError(f"Unsupported export format: {format}")
        except Exception as e:
            logger.error(f"Error exporting topology: {e}")
            return None

    # Helper methods for topology discovery
    def _get_lldp_neighbors(self, device: TopologyNode) -> List[Dict]:
        """Get LLDP neighbors for a device."""
        # Implementation would use SNMP or API calls to get LLDP information
        return []

    def _get_cdp_neighbors(self, device: TopologyNode) -> List[Dict]:
        """Get CDP neighbors for a device."""
        # Implementation would use SNMP or API calls to get CDP information
        return []

    def _get_stp_info(self, device: TopologyNode) -> List[Dict]:
        """Get STP information for a device."""
        # Implementation would use SNMP or API calls to get STP information
        return []

    def _get_routing_table(self, device: TopologyNode) -> List[Dict]:
        """Get routing table for a device."""
        # Implementation would use SNMP or API calls to get routing information
        return []
